# Use Debian Bookworm as the base image
FROM debian:12

# Install redis-server
RUN apt-get update && apt-get install -y \
	redis-server \
	&& rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Redis port
EXPOSE 6379

# Define the entrypoint and default command
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
