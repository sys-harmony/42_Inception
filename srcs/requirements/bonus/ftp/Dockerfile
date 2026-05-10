# Use Debian Bookworm as the base image
FROM debian:12

# Install vsftpd (Very Secure FTP Daemon)
RUN apt-get update && apt-get install -y \
	vsftpd \
	&& rm -rf /var/lib/apt/lists/*

# Copy the server configuration file
COPY conf/vsftpd.conf /etc/vsftpd.conf

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal ports (default 21, 40000-40005) dynamically injected at build time
ARG FTP_PORT=21
ARG FTP_PASV_MIN_PORT=40000
ARG FTP_PASV_MAX_PORT=40005
EXPOSE ${FTP_PORT} ${FTP_PASV_MIN_PORT}-${FTP_PASV_MAX_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["vsftpd", "/etc/vsftpd.conf"]
