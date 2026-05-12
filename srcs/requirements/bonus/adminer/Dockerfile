# Use Debian Bookworm as the base image for consistency
FROM debian:12

# Prevent interactive prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Install PHP, the PHP-MySQL extension and wget (to download Adminer)
RUN apt-get update && apt-get install -y \
	php8.2 php8.2-mysql \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Create the web directory
RUN mkdir -p /var/www/html

# Download the specific version of Adminer directly into the web directory
# We rename it to index.php so the server loads it by default
ARG ADMINER_VERSION=5.4.2
RUN wget https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php -O /var/www/html/index.php

# Ensure proper permissions
RUN chown -R www-data:www-data /var/www/html

# Set the working directory
WORKDIR /var/www/html

# Copy the entrypoint script into the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 8080) dynamically injected at build time
ARG ADMINER_PORT=8080
EXPOSE ${ADMINER_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["php"]
