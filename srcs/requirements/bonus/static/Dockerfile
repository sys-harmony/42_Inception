# Use Debian Bookworm as the base image
FROM debian:12

# Install lighttpd and clean up apt cache to keep the image slim
RUN apt-get update && apt-get install -y \
	lighttpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy the configuration file
COPY ./conf/lighttpd.conf /etc/lighttpd/lighttpd.conf

# Copy our static files to the document root
COPY www /var/www/html

# Ensure the web server user (www-data) owns the files for proper access
RUN chown -R www-data:www-data /var/www/html

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 80 (internal container port)
EXPOSE 80

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -D: don't go to background (foreground mode, essential for Docker)
# -f: path to the configuration file
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
