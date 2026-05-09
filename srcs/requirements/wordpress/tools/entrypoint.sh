#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'php-fpm8.2'
if [ "$1" = 'php-fpm8.2' ]; then

    # 1. Update PHP-FPM listening port dynamically before starting
    # The regex '^listen = .*' ensures it works even if the container restarts
    sed -i "s/^listen = .*/listen = ${WP_PORT}/" /etc/php/8.2/fpm/pool.d/www.conf

    # 2. Dynamic Site URL Calculation
    # Computes the absolute WordPress URL, appending the external NGINX port
    # if it differs from the standard 443. This prevents redirection loops.
    if [ "$NGINX_HOST_PORT" = "443" ]; then
        SITE_URL="https://$DOMAIN_NAME"
    else
        SITE_URL="https://$DOMAIN_NAME:$NGINX_HOST_PORT"
    fi

    # 3. Persistence Check
    # Skips the entire installation setup if 'wp-config.php' already exists on the volume
    if [ ! -f "/var/www/html/wp-config.php" ]; then

        # 4. Fetch secrets from Docker secret mount points
        # Retrieves sensitive credentials from Docker secret files
        MARIADB_PASSWORD=$(cat /run/secrets/db_password)
        WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
        WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

        # 5. Fail-fast validation
        # Ensures all necessary credentials are present before attempting installation

        # Database checks
        if [ -z "$MARIADB_HOST" ] || [ -z "$MARIADB_DATABASE" ] || [ -z "$MARIADB_USER" ] || [ -z "$MARIADB_PASSWORD" ]; then
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

        # 6. Service Dependencies
        # Ensures MariaDB is ready before running WP-CLI commands
        echo "Waiting for MariaDB to be ready..."
        until mariadb -h"$MARIADB_HOST" -P "$MARIADB_PORT" -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
            sleep 2
        done

        # 7. WordPress Configuration Logic
        echo "WordPress not found. Starting installation..."

        # Downloads the WordPress core files
        wp core download --allow-root

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

        # 8. Redis Setup (Bonus)
        echo "Configuring Redis Cache with authentication..."
        
        # Fetch the redis password from secret to use it in wp-config
        REDIS_PWD=$(cat /run/secrets/redis_password)

        # Fallback to default port 6379 if REDIS_PORT is empty to avoid WP-CLI errors
        ACTUAL_REDIS_PORT=${REDIS_PORT:-6379}

        wp plugin install redis-cache --activate --allow-root

        # Injects Redis connection constants into wp-config.php
        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$ACTUAL_REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root

        # Enables the object cache to start using Redis
        wp redis enable --allow-root

        # Finalizes file permissions for the web server (www-data)
        chown -R www-data:www-data /var/www/html
        chmod -R 775 /var/www/html
        echo "WordPress installed successfully."

    else

        # 9. Dynamic Update on Restart
        # If wp-config.php already exists (persisted volume), we update the database host
        # to seamlessly apply any potential port changes from the .env file without reinstalling.
        echo "WordPress is already installed. Updating Database Host in case the port changed..."
        wp config set DB_HOST "$MARIADB_HOST:$MARIADB_PORT" --allow-root

        # Ensures the WordPress database reflects the current NGINX external port.
        # This prevents the CMS from forcibly redirecting users to an old or default port.
        echo "Updating Site URL in case the NGINX host port changed..."
        wp option update home "$SITE_URL" --allow-root
        wp option update siteurl "$SITE_URL" --allow-root

        # Update Redis configuration in case the port or password changed
        echo "Updating Redis configuration..."
        REDIS_PWD=$(cat /run/secrets/redis_password)
        
        # Fallback to default port 6379 if REDIS_PORT is empty to avoid WP-CLI errors
        ACTUAL_REDIS_PORT=${REDIS_PORT:-6379}

        wp config set WP_REDIS_HOST redis --allow-root
        wp config set WP_REDIS_PORT "$ACTUAL_REDIS_PORT" --raw --allow-root
        wp config set WP_REDIS_PASSWORD "$REDIS_PWD" --allow-root
        
        # Re-enable the object cache to ensure it's active with new settings
        wp redis enable --allow-root

    fi
fi

# 10. Execute the command from CMD
# 'exec' replaces the shell with the PHP-FPM process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
