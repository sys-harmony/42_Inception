#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points (RAM-only files)
# This avoids passing sensitive passwords through environment variables
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# 2. Fail-fast validation
# Ensures all necessary credentials are present before attempting installation
if [ -z "$MYSQL_ROOT_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: Missing mandatory database environment variables or secrets." >&2
    exit 1
fi

# 3. MariaDB Installation Logic
# Only run initialization if the command passed is 'mysqld'
if [ "$1" = 'mysqld' ]; then
    # Custom marker file check to ensure persistence (skips if already initialized)
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        echo "Initializing MariaDB database..."

        # Ensure the mysql user owns the data directory for proper permissions
        chown -R mysql:mysql /var/lib/mysql

        # Create system tables and initial database structure
        mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

        # Use bootstrap to configure users and database privileges
        # This executes SQL commands without starting the full network server
        mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        # Create the marker file to confirm successful first-time setup
        touch /var/lib/mysql/.initialized
        echo "MariaDB initialized successfully."
    fi
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the MariaDB process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
