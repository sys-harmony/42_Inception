# Use Debian Bookworm as the base image
FROM debian:12

# Update system and install HAProxy
RUN apt-get update && apt-get install -y \
	haproxy \
	&& rm -rf /var/lib/apt/lists/*

# Copy our custom security configuration
COPY conf/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the proxy port
EXPOSE 2375

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -f: Specifies the path to the configuration file.
# By default, HAProxy runs in the foreground unless '-D' is specified, 
# ensuring the container remains active and manageable by Docker.
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
