# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install PHP-FPM, MySQL extensions, and required tools
RUN apt-get update && apt-get install -y \
	php8.2-fpm php8.2-mysql php8.2-curl php8.2-gd php8.2-intl \
	php8.2-mbstring php8.2-xml php8.2-zip \
	wget mariadb-client ca-certificates && \
	rm -rf /var/lib/apt/lists/*

# Install WP-CLI (WordPress Command Line Interface)
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x wp-cli.phar && \
	mv wp-cli.phar /usr/local/bin/wp

# Create directory for PHP-FPM runtime files and set correct permissions
RUN mkdir -p /run/php && \
	chown -R www-data:www-data /run/php

# Configure PHP-FPM to listen on port 9000 instead of a Unix socket for network communication
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

# Set the working directory to the web root
WORKDIR /var/www/html

# Copy the entrypoint script into the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default PHP-FPM port (Documentation purpose only)
# The actual listening port is dynamically injected at runtime via the entrypoint.sh script
EXPOSE 9000

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -F: Forces php-fpm to run in the foreground rather than becoming a daemon.
# This ensures the container stays active and that logs are sent to stdout/stderr.
CMD ["php-fpm8.2", "-F"]
