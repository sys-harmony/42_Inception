#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch the secret from the Docker secret mount point
FTP_PWD=$(cat /run/secrets/ftp_password)

# 2. Create the FTP user if it doesn't exist
# We use the environment variable FTP_USER from the .env file
if ! id "$FTP_USER" >/dev/null 2>&1; then
    echo "Creating FTP user: $FTP_USER..."
    useradd -m -s /bin/bash "$FTP_USER"
    echo "$FTP_USER:$FTP_PWD" | chpasswd
    
    # Set the home directory to the WordPress volume path
    usermod -d /var/www/html "$FTP_USER"
fi

# 3. Configuration for vsftpd
# We generate the config file dynamically to ensure correct settings
cat << EOF > /etc/vsftpd.conf
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

# 4. Fix permissions
# WordPress files often belong to www-data. We ensure our FTP user 
# can actually modify/delete them by taking ownership.
echo "Setting permissions for /var/www/html..."
chown -R "$FTP_USER:$FTP_USER" /var/www/html
chmod -R 755 /var/www/html

# 5. Prepare the runtime environment
mkdir -p /var/run/vsftpd/empty

echo "Starting FTP server for user: $FTP_USER"

# 6. Run vsftpd with the generated configuration
exec vsftpd /etc/vsftpd.conf
