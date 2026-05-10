#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'lighttpd'
if [ "$1" = "lighttpd" ]; then

    # 1. Fail-fast validation
    # Ensures the mandatory STATIC_PORT is set before proceeding
    if [ -z "$STATIC_PORT" ]; then
        echo "Error: Missing STATIC_PORT environment variable." >&2
        exit 1
    fi

    # 2. Dynamic Port Configuration
    # Updates the Lighttpd server.port value to match the .env configuration.
    # The regex ensures accuracy even if the container restarts multiple times.
    echo "Configuring Lighttpd to listen on port: $STATIC_PORT"
    sed -i "s/^server.port.*/server.port = ${STATIC_PORT}/" /etc/lighttpd/lighttpd.conf
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the Lighttpd process so it becomes PID 1.
exec "$@"
