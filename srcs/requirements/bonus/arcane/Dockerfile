# Use Debian Bookworm as the base image
FROM debian:12

# Define the version argument (passed from docker-compose.yml)
ARG ARCANE_VERSION

# Update system and install required base utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for the application
WORKDIR /app

# Download the pre-compiled Linux AMD64 binary for the specific version
RUN curl -fsSL https://github.com/getarcaneapp/arcane/releases/download/v${ARCANE_VERSION}/arcane_linux_amd64 -o arcane \
    && chmod +x arcane

# Copy the entrypoint script into the container and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Arcane port
EXPOSE 3552

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["./arcane"]
