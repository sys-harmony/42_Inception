#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Dynamic Configuration via Command Arguments
# If the command is 'php', we inject the built-in server parameters.
if [ "$1" = "php" ]; then

    # 2. Fail-fast validation
    # Ensures the mandatory ADMINER_PORT is set before proceeding
    if [ -z "$ADMINER_PORT" ]; then
        echo "Error: Missing ADMINER_PORT environment variable." >&2
        exit 1
    fi

    # 3. Arguments Injection
    # -S 0.0.0.0:${ADMINER_PORT}: Starts the PHP built-in web server on the dynamic port.
    # -t /var/www/html: Sets the document root where Adminer (index.php) is located.
    echo "Starting Adminer on port: $ADMINER_PORT"
    set -- "$@" "-S" "0.0.0.0:${ADMINER_PORT}" "-t" "/var/www/html"
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the PHP process so it becomes PID 1.
exec "$@"
