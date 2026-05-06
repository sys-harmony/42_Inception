#!/bin/sh

# Stops the script immediately if any command fails
set -e

# 1. Loads secrets into environment variables
export ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
export JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

# 2. Configures the Docker client to talk to HAProxy instead of the local socket
if [ -n "$HAPROXY_HOST" ]; then
    export DOCKER_HOST="tcp://${HAPROXY_HOST}:2375"
fi

# 3. Execute the command from CMD
# 'exec' replaces the shell with the Arcane process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
