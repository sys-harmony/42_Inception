#!/bin/sh

# Stop the script immediately if any command fails
set -e

if [ "$1" = "redis-server" ]; then
    # 1. Fetch the secret from Docker secret mount point
    # Retrieves the password from the Docker secret file
    REDIS_PASSWORD=$(cat /run/secrets/redis_password)

    # 2. Fail-fast validation
    if [ -z "$REDIS_PASSWORD" ]; then
        echo "Error: REDIS_PASSWORD secret is missing." >&2
        exit 1
    fi

    echo "Starting Redis server..."

    # Append arguments to $@
    set -- "$@" --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the target process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
