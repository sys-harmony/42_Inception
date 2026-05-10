#!/bin/sh

# Stop the script immediately if any command fails
set -e

# Only run setup logic if the command passed is 'nginx'
if [ "$1" = "nginx" ]; then

    # 1. Fail-fast validation
    # Ensures all mandatory environment variables are set before proceeding
    if [ -z "$DOMAIN_NAME" ] || [ -z "$NGINX_PORT" ] || [ -z "$WP_PORT" ]; then
        echo "Error: Missing DOMAIN_NAME, NGINX_PORT and/or WP_PORT environment variable(s)." >&2
        exit 1
    fi

    # 2. Dynamic Configuration Injection
    # Replaces the placeholders in the template with the actual domain name and ports at runtime
    echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
    sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf
    sed -i "s/__NGINX_PORT__/$NGINX_PORT/g" /etc/nginx/nginx.conf
    sed -i "s/__WP_PORT__/$WP_PORT/g" /etc/nginx/nginx.conf

    # 3. SSL Certificate Generation
    # Creates a self-signed certificate if not present (persistence check)
    CERTS_DIR="/etc/nginx/ssl"

    if [ ! -f "$CERTS_DIR/$DOMAIN_NAME.crt" ]; then
        echo "[INFO] Generating self-signed SSL certificate..."
        
        mkdir -p "$CERTS_DIR"
        
        # Generate a non-interactive RSA 2048-bit key and certificate valid for 365 days
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$CERTS_DIR/$DOMAIN_NAME.key" \
            -out "$CERTS_DIR/$DOMAIN_NAME.crt" \
            -subj "/C=FR/ST=GrandEst/L=Mulhouse/O=42/OU=Inception/CN=$DOMAIN_NAME"
            
        echo "[INFO] SSL certificate generated successfully."
    fi
fi

# 4. Execute the command from CMD
# 'exec' replaces the shell with the NGINX process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
