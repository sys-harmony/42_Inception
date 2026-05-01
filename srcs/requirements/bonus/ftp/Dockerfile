# Use Debian Bookworm as the base image
FROM debian:12

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose FTP port and passive mode range
EXPOSE 21 40000-40005

# Prepares the environment (users, permissions, secrets) before launching
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default binary executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["vsftpd", "/etc/vsftpd.conf"]
