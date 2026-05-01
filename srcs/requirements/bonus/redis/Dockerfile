# Use Debian Bookworm as the base image
FROM debian:12

# Install redis-server
RUN apt-get update && apt-get install -y \
	redis-server \
	&& rm -rf /var/lib/apt/lists/*

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Redis port
EXPOSE 6379

# Prepares the environment (secrets) before launching the application
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Redis is started by the entrypoint with the runtime secret applied
