# Use Debian Bookworm as the base image
FROM debian:12

# Update system and install HAProxy
RUN apt-get update && apt-get install -y \
	haproxy \
	&& rm -rf /var/lib/apt/lists/*

# Copy our custom security configuration
COPY conf/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Expose the proxy port
EXPOSE 2375

# Run HAProxy in the foreground
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
