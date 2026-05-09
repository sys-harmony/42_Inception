#!/bin/sh

# Stop the script immediately if any command fails
set -e

if [ "$1" = "redis-server" ]; then

    # 1. Fetch the secret from Docker secret mount point
    # Retrieves the password from the Docker secret file
    REDIS_PASSWORD=$(cat /run/secrets/redis_password)

    # 2. Fail-fast validation
    if [ -z "$REDIS_PASSWORD" ] || [ -z "$REDIS_PORT" ]; then # <--- AJOUTER LA VÉRIFICATION DU PORT
        echo "Error: REDIS_PASSWORD secret or REDIS_PORT variable is missing." >&2
        exit 1
    fi

    echo "Starting Redis server on port $REDIS_PORT..."

    # 3. Dynamic Configuration via Command Arguments
    # Instead of modifying a config file, we inject parameters directly 
    # into the command line arguments using 'set --'.
    # --bind 0.0.0.0: Allows connections from other containers (WordPress)
    # --protected-mode no: Required for remote connections when bind is used
    set -- "$@" --port "$REDIS_PORT" --bind 0.0.0.0 --requirepass "$REDIS_PASSWORD" --protected-mode no
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the target process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
