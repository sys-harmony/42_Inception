#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Fetch the secret
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Validation
if [ -z "$REDIS_PASSWORD" ]; then
    echo "Error: REDIS_PASSWORD secret is missing." >&2
    exit 1
fi

echo "Starting Redis server..."

# Start Redis and bind it to all interfaces so WordPress can connect
# --requirepass secures Redis with our secret
exec redis-server --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
