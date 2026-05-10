#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'mariadbd'
if [ "$1" = 'mariadbd' ]; then

    # 1. Fail-fast validation
    # The port is required for BOTH installation and restarts
    if [ -z "$MARIADB_PORT" ]; then
        echo "Error: Missing MARIADB_PORT environment variable." >&2
        exit 1
    fi

    # 2. Persistence Check
    # Skips the entire installation setup if '.initialized' already exists on the volume
    if [ ! -f "/var/lib/mysql/.initialized" ]; then
        
        # 3. Fetch secrets from Docker secret mount points (RAM-only files)
        # This avoids passing sensitive passwords through environment variables
        MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)

        # 4. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation
        if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
            echo "Error: Missing database environment variable(s) and/or secret(s)." >&2
            exit 1
        fi

        # 5. MariaDB Installation Logic
        echo "Initializing MariaDB database..."

        # Ensure the mysql user owns the data directory for proper permissions
        chown -R mysql:mysql /var/lib/mysql

        # Create system tables and initial database structure
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

        # Use bootstrap to configure users and database privileges
        # This executes SQL commands without starting the full network server
        mariadbd --user=mysql --datadir=/var/lib/mysql --bootstrap <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
        # Create the marker file to confirm successful first-time setup
        touch /var/lib/mysql/.initialized
        echo "MariaDB initialized successfully."
    fi

    # 6. Dynamic Configuration via Command Arguments
    # Injects parameters directly into the command line arguments using 'set --'.
    # We must specify --user=mysql to avoid the "run as root" error
    # --bind-address=0.0.0.0 allows connections from other containers
    set -- "$@" --user=mysql --bind-address=0.0.0.0 --port="$MARIADB_PORT"
fi

# 7. Execute the command from CMD
# 'exec' replaces the shell with the MariaDB process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
