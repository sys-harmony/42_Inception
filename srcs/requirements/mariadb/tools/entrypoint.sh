#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# 2. Fail-fast validation
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: Missing mandatory database environment variables or secrets." >&2
    exit 1
fi

# 3. MariaDB Installation Logic
if [ "$1" = 'mysqld' ]; then
    # Marker file check to prevent re-initialization
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        echo "Initializing MariaDB database..."

        chown -R mysql:mysql /var/lib/mysql
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

        # Use bootstrap to configure users and database privileges
        mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        # Create the marker file to confirm success
        touch /var/lib/mysql/.initialized
        echo "MariaDB initialized successfully."
    fi
fi

# 4. Execute the command from CMD (PID 1)
exec "$@"
