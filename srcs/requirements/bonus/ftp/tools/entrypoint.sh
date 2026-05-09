#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'vsftpd'
if [ "$1" = "vsftpd" ]; then

    # 1. Fetch secrets from Docker secret mount points (RAM-only files)
    # This avoids passing sensitive passwords through environment variables
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)

    # 2. Fail-fast validation
    # Ensures all necessary credentials are present before attempting installation
    if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
        echo "Error: FTP_USER or ftp_password secret is missing." >&2
        exit 1
    fi

    # 3. User Creation and Permissions
    # Create the FTP user with a specific UID to match a common standard or 
    # simply add him to the www-data group.
    if ! id "$FTP_USER" >/dev/null 2>&1; then
        # We create the user and force him into the www-data group (GID 33)
        useradd -m -d /var/www/html -s /bin/bash -G www-data "$FTP_USER"
        echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    else
        usermod -d /var/www/html -G www-data "$FTP_USER"
    fi

    # We give ownership to www-data (so WordPress can write)
    # and we set permissions to 775 (so the group www-data, including our FTP user, can write)
    echo "Setting permissions for /var/www/html..."
    chown -R www-data:www-data /var/www/html
    chmod -R 775 /var/www/html

    # 4. Prepare the runtime environment
    # vsftpd requires this specific directory to run for isolation (chroot)
    mkdir -p /var/run/vsftpd/empty

    # 5. Dynamic Port Configuration
    # Injects the ports defined in the .env file into the vsftpd configuration.
    # This ensures the server listens on the correct ports for both command and passive modes.
    echo "Configuring dynamic ports for vsftpd..."
    sed -i "s/^listen_port=.*/listen_port=${FTP_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_min_port=.*/pasv_min_port=${FTP_PASV_MIN_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_max_port=.*/pasv_max_port=${FTP_PASV_MAX_PORT}/" /etc/vsftpd.conf

    echo "Starting FTP server for user: $FTP_USER"
fi

# 6. Execute the command from CMD
# 'exec' replaces the shell with the vsftpd process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
