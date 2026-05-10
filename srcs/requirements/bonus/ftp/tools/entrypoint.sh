#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'vsftpd'
if [ "$1" = "vsftpd" ]; then

    # 1. Fetch secrets from Docker secret mount points (RAM-only files)
    FTP_PASSWORD=$(cat /run/secrets/ftp_password)

    # 2. Fail-fast validation
    # Check for credentials
    if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
        echo "Error: Missing FTP_USER environment variable and/or FTP_PASSWORD secret." >&2
        exit 1
    fi

    # Check for network variables
    if [ -z "$FTP_PORT" ] || [ -z "$FTP_PASV_MIN_PORT" ] || [ -z "$FTP_PASV_MAX_PORT" ]; then
        echo "Error: Missing FTP port environment variable(s)." >&2
        exit 1
    fi

    # 3. User Creation and Permissions
    if ! id "$FTP_USER" >/dev/null 2>&1; then
        useradd -m -d /var/www/html -s /bin/bash -G www-data "$FTP_USER"
        echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    else
        usermod -d /var/www/html -G www-data "$FTP_USER"
    fi

    echo "Setting permissions for /var/www/html..."
    chown -R www-data:www-data /var/www/html
    chmod -R 775 /var/www/html

    # 4. Prepare the runtime environment
    mkdir -p /var/run/vsftpd/empty

    # 5. Dynamic Port Configuration
    # Injects the ports defined in the .env file into the vsftpd configuration
    echo "Configuring dynamic ports for vsftpd..."
    sed -i "s/^listen_port=.*/listen_port=${FTP_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_min_port=.*/pasv_min_port=${FTP_PASV_MIN_PORT}/" /etc/vsftpd.conf
    sed -i "s/^pasv_max_port=.*/pasv_max_port=${FTP_PASV_MAX_PORT}/" /etc/vsftpd.conf

    echo "Starting FTP server for user: $FTP_USER"
fi

# 6. Execute the command from CMD
exec "$@"
