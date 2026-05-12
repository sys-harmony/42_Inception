# Use Debian Bookworm as the base image
FROM debian:12

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites for adding the official HAProxy repository
RUN apt-get update && apt-get install -y \
    curl gnupg ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Register the HAProxy official repository (3.2 LTS)
# HAProxy 3.2 is required: Debian 12 ships 2.6 which strips hop-by-hop headers
# (Connection, Upgrade) even when re-injected via http-request rules, making
# Docker's exec/attach TCP upgrade impossible in HTTP mode.
RUN curl https://haproxy.debian.net/haproxy-archive-keyring.gpg \
        --create-dirs --output /etc/apt/keyrings/haproxy-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/haproxy-archive-keyring.gpg] \
        https://haproxy.debian.net bookworm-backports-3.2 main" \
        > /etc/apt/sources.list.d/haproxy.list

# Install the pinned HAProxy version
# The '*' suffix matches the Debian revision suffix (e.g. 3.2.19-1~bpo12+1)
ARG HAPROXY_VERSION=3.2.19
RUN apt-get update && apt-get install -y \
    "haproxy=${HAPROXY_VERSION}*" \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom security configuration
COPY conf/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

# Copy the initialization script to the container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose the internal port (default 2375) dynamically injected at build time
ARG HAPROXY_PORT=2375
EXPOSE ${HAPROXY_PORT}

# Set the entrypoint script to handle setup and environment preparation at container start
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command executed as PID 1 via the entrypoint's 'exec "$@"'
# -f: Specifies the path to the configuration file.
# By default, HAProxy runs in the foreground unless '-D' is specified,
# ensuring the container remains active and manageable by Docker.
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
