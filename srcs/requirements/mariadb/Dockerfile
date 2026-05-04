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

# Expose the default MariaDB port
EXPOSE 3306

# Define the script that will handle the initial setup
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed by the entrypoint script (PID 1)
# We must specify --user=mysql to avoid the "run as root" error
# --bind-address=0.0.0.0 allows connections from other containers
CMD ["mariadbd", "--user=mysql", "--bind-address=0.0.0.0", "--port=3306"]
