# Use Debian Bookworm as the base image
FROM debian:12

# Update system and install required base utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for the application
WORKDIR /app

# Download the pre-compiled Linux AMD64 binary directly using curl
RUN curl -fsSL https://github.com/getarcaneapp/arcane/releases/download/v1.18.1/arcane_linux_amd64 -o arcane \
    && chmod +x arcane

# Copy the entrypoint script into the container and make it executable
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the default Arcane port
EXPOSE 3552

# Set the entrypoint to our script so it loads secrets first
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Start the application directly from the binary
CMD ["./arcane"]
