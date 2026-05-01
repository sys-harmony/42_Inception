# Stage 1: Temporary stage to get the binary
FROM ghcr.io/getarcaneapp/arcane:latest AS builder

# Stage 2: Final image based on Debian 12
FROM debian:12

# Install requirements
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /app/data

# Copy the binary from the builder stage
COPY --from=builder /app/arcane /usr/local/bin/arcane
RUN chmod +x /usr/local/bin/arcane

# Copy and prepare the entrypoint script
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 3552
EXPOSE 3552

# Prepares the environment (secrets) before launching the application
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default binary executed as PID 1 via the entrypoint's 'exec "$@"'
CMD ["arcane"]
