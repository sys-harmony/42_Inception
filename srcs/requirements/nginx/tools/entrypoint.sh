#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fail-fast validation
# Ensures DOMAIN_NAME is set before generating certificates
if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME environment variable is missing." >&2
    exit 1
fi

# 2. Dynamic Configuration Injection
# Replaces the placeholder in the template with the actual domain name at runtime
echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf

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

# 4. Execute the command from CMD
# 'exec' replaces the shell with the NGINX process so it becomes PID 1.
# This ensures it receives SIGTERM signals directly for a clean shutdown.
exec "$@"
