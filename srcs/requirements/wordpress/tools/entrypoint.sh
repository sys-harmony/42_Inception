#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch secrets from Docker secret mount points
# Retrieves sensitive credentials from Docker secret files
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# 2. Fail-fast validation
# Ensures all necessary credentials are present before attempting installation

# Database checks
if [ -z "$MYSQL_HOSTNAME" ] || [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ]; then
    echo "Error: Missing database environment variables or secrets." >&2
    exit 1
fi

# Admin checks
if [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
    echo "Error: Missing admin environment variables or secrets." >&2
    exit 1
fi

# Site and Secondary User checks
if [ -z "$DOMAIN_NAME" ] || [ -z "$WP_TITLE" ] || [ -z "$WP_USER" ] || [ -z "$WP_USER_PASSWORD" ] || [ -z "$WP_USER_EMAIL" ]; then
    echo "Error: Missing site or secondary user environment variables." >&2
    exit 1
fi

# 3. Service Initialization & Dependencies
# Service availability check: ensures the database is up before running WP-CLI commands
echo "Waiting for MariaDB to be ready..."
until mysql -h"$MYSQL_HOSTNAME" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done

# 4. WordPress & Redis Configuration Logic
# Skips if wp-config.php exists (persistence check for already initialized volumes)
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "WordPress not found. Starting installation..."

    # Downloads the WordPress core files
    wp core download --allow-root

    # Generates wp-config.php with provided database credentials
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOSTNAME" \
        --allow-root

    # Configures the database and creates the primary administrator account
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root

    # Creates the mandatory non-administrator user required by the subject
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --allow-root

    # Redis Setup (Bonus)
    echo "Configuring Redis Cache with authentication..."
    
    # Fetch the redis password from secret to use it in wp-config
    REDIS_PWD=$(cat /run/secrets/redis_password)

    wp plugin install redis-cache --activate --allow-root

    # Injects Redis connection constants into wp-config.php
    wp config set WP_REDIS_HOST redis --allow-root
    wp config set WP_REDIS_PORT 6379 --raw --allow-root
    wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root

    # Enables the object cache to start using Redis
    wp redis enable --allow-root

    # Finalizes file permissions for the web server (www-data)
    chown -R www-data:www-data /var/www/html
    chmod -R 755 /var/www/html
    echo "WordPress installed successfully."
fi

# 5. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
