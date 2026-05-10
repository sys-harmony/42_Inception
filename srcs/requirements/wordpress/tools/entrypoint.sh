#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'php-fpm8.2'
if [ "$1" = 'php-fpm8.2' ]; then

    # 1. Fetch the Redis Password (Bonus) from Docker secret mount points
    REDIS_PASSWORD=$(cat /run/secrets/redis_password)

    # 2. Fail-fast validation
    # These variables are strictly required for BOTH installation and restarts.
    # We check them before doing any file modifications or variable calculations.
    if [ -z "$WP_PORT" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$NGINX_HOST_PORT" ] || [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_PORT" ]; then
        echo "Error: Missing WP_PORT, DOMAIN_NAME, NGINX_HOST_PORT, MARIADB_HOST and/or MARIADB_PORT environment variable(s)." >&2
        exit 1
    fi

    if [ -z "$REDIS_PORT" ] || [ -z "$REDIS_PASSWORD" ]; then
        echo "Error: Missing REDIS_PORT environment variable and/or REDIS_PASSWORD secret." >&2
        exit 1
    fi

    # 3. Update PHP-FPM listening port dynamically before starting
    # The regex '^listen = .*' ensures it works even if the container restarts
    sed -i "s/^listen = .*/listen = ${WP_PORT}/" /etc/php/8.2/fpm/pool.d/www.conf

    # 4. Dynamic Site URL Calculation
    # Computes the absolute WordPress URL, appending the external NGINX port
    # if it differs from the standard 443. This prevents redirection loops.
    if [ "$NGINX_HOST_PORT" = "443" ]; then
        SITE_URL="https://$DOMAIN_NAME"
    else
        SITE_URL="https://$DOMAIN_NAME:$NGINX_HOST_PORT"
    fi

    # 5. Persistence Check
    # Skips the entire installation setup if 'wp-config.php' already exists on the volume
    if [ ! -f "/var/www/html/wp-config.php" ]; then

        # 6. Fetch secrets from Docker secret mount points
        # Retrieves sensitive credentials from Docker secret files
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)
        WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
        WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

        # 7. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation

        # Database checks
        if [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
            echo "Error: Missing database environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Admin checks
        if [ -z "$WP_ADMIN_USER" ] || [ -z "$WP_ADMIN_PASSWORD" ] || [ -z "$WP_ADMIN_EMAIL" ]; then
            echo "Error: Missing admin environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Secondary User checks
        if [ -z "$WP_USER" ] || [ -z "$WP_USER_PASSWORD" ] || [ -z "$WP_USER_EMAIL" ]; then
            echo "Error: Missing secondary user environment variable(s) and/or secret." >&2
            exit 1
        fi

        # Other checks
        if [ -z "$WP_TITLE" ] || [ -z "$WP_VERSION" ]; then
            echo "Error: Missing WP_TITLE and/or WP_VERSION environment variable(s)." >&2
            exit 1
        fi

        # 8. Service Dependencies
        # Ensures MariaDB is ready before running WP-CLI commands
        echo "Waiting for MariaDB to be ready..."
        until mariadb -h"$MARIADB_HOST" -P "$MARIADB_PORT" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
            sleep 2
        done

        # 9. WordPress Configuration Logic
        echo "WordPress not found. Starting installation..."

        # Downloads the specific version of WordPress core files
        echo "Downloading WordPress version $WP_VERSION..."
        wp core download --version="$WP_VERSION" --allow-root

        # Generates wp-config.php with provided database credentials
        wp config create \
            --dbname="$MARIADB_DATABASE" \
            --dbuser="$MARIADB_USER" \
            --dbpass="$MARIADB_PASSWORD" \
            --dbhost="$MARIADB_HOST:$MARIADB_PORT" \
            --allow-root

        # Configures the database and creates the primary administrator account
        wp core install \
            --url="$SITE_URL" \
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

        # We hardcode the URLs in wp-config.php to override database settings
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # 10. Redis Setup (Bonus)
        echo "Configuring Redis Cache with authentication..."
        wp plugin install redis-cache --activate --allow-root

        # Injects Redis connection constants into wp-config.php
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root

        # Enables the object cache to start using Redis
        wp redis enable --allow-root

        # Finalizes file permissions for the web server (www-data)
        chown -R www-data:www-data /var/www/html
        chmod -R 775 /var/www/html
        echo "WordPress installed successfully."

    else
    
        # 11. Dynamic Update on Restart
        # If wp-config.php exists (persisted volume), we refresh the configuration.
        echo "WordPress is already installed. Preparing updates..."

        # Temporarily disable object cache to avoid WP-CLI bootstrap failures
        OBJECT_CACHE="/var/www/html/wp-content/object-cache.php"
        if [ -f "$OBJECT_CACHE" ]; then
            mv "$OBJECT_CACHE" "${OBJECT_CACHE}.disabled"
        fi

        # Update the filesystem configuration (wp-config.php)
        wp config set DB_HOST "$MARIADB_HOST:$MARIADB_PORT" --allow-root
        wp config set WP_HOME "$SITE_URL" --allow-root
        wp config set WP_SITEURL "$SITE_URL" --allow-root

        # Update the persistent database options (MariaDB)
        wp option update home "$SITE_URL" --allow-root
        wp option update siteurl "$SITE_URL" --allow-root

        # Update Redis connection constants (wp-config.php)
        echo "Updating Redis configuration..."
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --allow-root
        
        # Re-enable object cache
        rm -f "${OBJECT_CACHE}.disabled"
        wp redis enable --allow-root
        
        echo "Dynamic configuration updated successfully."
    fi
fi

# 12. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
