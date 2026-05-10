#!/bin/sh

# Stops the script immediately if any command fails
set -e

# Only run setup logic if the command passed is './arcane'
if [ "$1" = "./arcane" ]; then

    # 1. Fetch secrets from Docker secret mount points
    ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
    JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

    # 2. Fail-fast validation
    # Check for secrets and mandatory environment variables
    if [ -z "$ENCRYPTION_KEY" ] || [ -z "$JWT_SECRET" ]; then
        echo "Error: Arcane secrets (encryption key or JWT secret) are missing." >&2
        exit 1
    fi

    if [ -z "$PORT" ]; then
        echo "Error: ARCANE_PORT (mapped to PORT) environment variable is missing." >&2
        exit 1
    fi

    # 3. Export secrets to environment for the application
    export ENCRYPTION_KEY
    export JWT_SECRET

    # 4. Configures the Docker client to talk to HAProxy instead of the local socket
    if [ -n "$HAPROXY_HOST" ]; then
        if [ -z "$HAPROXY_PORT" ]; then
            echo "Error: HAPROXY_HOST is set but HAPROXY_PORT is missing." >&2
            exit 1
        fi
        echo "Routing Docker traffic through HAProxy at ${HAPROXY_HOST}:${HAPROXY_PORT}"
        export DOCKER_HOST="tcp://${HAPROXY_HOST}:${HAPROXY_PORT}"
    fi
fi

# 5. Execute the command from CMD
# 'exec' replaces the shell with the Arcane process so it becomes PID 1.
exec "$@"
