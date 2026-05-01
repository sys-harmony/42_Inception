#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points
FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# 2. Fail-fast validation
if [ -z "$FTP_USER" ] || [ -z "$FTP_PASSWORD" ]; then
    echo "Error: FTP_USER or ftp_password secret is missing." >&2
    exit 1
fi

# 3. User Creation and Permissions
# Create the FTP user if it doesn't exist and set their password
if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd -m -d /var/www/html -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
else
    usermod -d /var/www/html "$FTP_USER"
fi

# Ensure the webroot is owned by the FTP user for upload capabilities
echo "Setting permissions for /var/www/html..."
chown -R "$FTP_USER:$FTP_USER" /var/www/html
chmod -R 755 /var/www/html

# 4. Prepare the runtime environment
# vsftpd requires this specific directory to run for isolation (chroot)
mkdir -p /var/run/vsftpd/empty

# Generate the vsftpd configuration used by the container
cat <<EOF > /etc/vsftpd.conf
# Run in the foreground (required for Docker containers)
listen=YES
listen_ipv6=NO

# Access rights for local users
local_enable=YES
write_enable=YES
local_umask=022

# Security & Chroot (isolates the user in their home directory)
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/run/vsftpd/empty

# Passive mode configuration (Crucial for Docker NAT networking)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40005
pasv_address=0.0.0.0
EOF

echo "Starting FTP server for user: $FTP_USER"

# 5. Execute the command from CMD
# 'exec' replaces the shell with the vsftpd process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
