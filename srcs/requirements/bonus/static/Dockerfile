# Use Debian Bookworm as the base image
FROM debian:12

# Install lighttpd and clean up apt cache
RUN apt-get update && apt-get install -y \
	lighttpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy the configuration file
COPY ./conf/lighttpd.conf /etc/lighttpd/lighttpd.conf

# Copy our static files to the document root
COPY www /var/www/html

# Ensure the web server user owns the files
RUN chown -R www-data:www-data /var/www/html

# Expose port 80 (internally, mapped via docker-compose)
EXPOSE 80

# Run lighttpd in the foreground
CMD ["lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"]
