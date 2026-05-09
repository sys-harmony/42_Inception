#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'haproxy'
if [ "$1" = "haproxy" ]; then

    # 1. Fail-fast validation
    # Ensures the mandatory HAPROXY_PORT is set before proceeding
    if [ -z "$HAPROXY_PORT" ]; then
        echo "Error: HAPROXY_PORT environment variable is missing." >&2
        exit 1
    fi

    # 2. Dynamic Port Configuration
    # Injects the dynamic port into the haproxy.cfg bind instruction.
    # This allows the socket proxy to adapt to .env changes without image rebuilds.
    echo "Configuring HAProxy to listen on port: $HAPROXY_PORT"
    sed -i "s/bind \*:2375/bind \*:${HAPROXY_PORT}/" /usr/local/etc/haproxy/haproxy.cfg
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the HAProxy process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
