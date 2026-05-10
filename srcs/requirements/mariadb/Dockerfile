# Use the stable Debian Bookworm as base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install MariaDB server and client
RUN apt-get update && apt-get install -y \
	mariadb-server mariadb-client && \
	rm -rf /var/lib/apt/lists/*

# Create required directories for the database and the socket
# and ensure the 'mysql' user owns them
RUN mkdir -p /var/lib/mysql /run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 3306) dynamically injected at build time
# The actual listening port is dynamically injected at runtime via the docker-compose.yml file
ARG MARIADB_PORT=3306
EXPOSE ${MARIADB_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# Overridden by docker-compose.yml at runtime to inject dynamic ports.
# We must specify --user=mysql to avoid the "run as root" error
# --bind-address=0.0.0.0 allows connections from other containers
CMD ["mariadbd", "--user=mysql", "--bind-address=0.0.0.0"]
