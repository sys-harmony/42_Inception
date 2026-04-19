# Use Debian Bookworm as the base image for consistency
FROM debian:12

# Install wget (to download Adminer), PHP, and the PHP-MySQL extension
RUN apt-get update && apt-get install -y \
	wget \
	php \
	php-mysql \
	&& rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download the latest version of Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
RUN wget https://www.adminer.org/latest.php -O /var/www/html/index.php

# Ensure proper permissions (optional but good practice)
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Expose port 8080
EXPOSE 8080

# Start PHP's built-in web server listening on all interfaces
CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
