# Use Debian Bookworm as the base image for consistency
FROM debian:12

# Install PHP, the PHP-MySQL extension and wget (to download Adminer)
RUN apt-get update && apt-get install -y \
	php8.2 php8.2-mysql \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
RUN wget https://github.com/vrana/adminer/releases/download/v5.4.2/adminer-5.4.2.php -O /var/www/html/index.php

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Expose port 8080
EXPOSE 8080

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -S 0.0.0.0:${ADMINER_PORT}: Starts the PHP built-in web server on the dynamic port.
# -t /var/www/html: Sets the document root where Adminer (index.php) is located.
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
