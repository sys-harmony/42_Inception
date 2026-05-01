#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fetch the secret from Docker secret mount point
# Retrieves the password from the Docker secret file
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# 2. Fail-fast validation
if [ -z "$REDIS_PASSWORD" ]; then
    echo "Error: REDIS_PASSWORD secret is missing." >&2
    exit 1
fi

echo "Starting Redis server..."

# 3. Start Redis with the secret fetched above
# 'exec' replaces the shell with the Redis process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
