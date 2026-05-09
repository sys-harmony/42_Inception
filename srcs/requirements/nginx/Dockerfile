# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install NGINX, OpenSSL (certificates), and wget (Docker healthcheck)
RUN apt-get update && apt-get install -y \
	nginx openssl wget && \
	rm -rf /var/lib/apt/lists/*

# Copy the NGINX configuration file into the container
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Copy the entrypoint script and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default NGINX port (Documentation purpose only)
# The actual listening port is dynamically injected at runtime via the entrypoint.sh script
EXPOSE 443

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -g "daemon off;": Runs NGINX in the foreground so the container doesn't exit
CMD ["nginx", "-g", "daemon off;"]
