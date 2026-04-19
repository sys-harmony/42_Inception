#!/bin/sh

# Stop the script immediately if any command fails
set -e

# 1. Fail-fast validation
if [ -z "$DOMAIN_NAME" ]; then
    echo "[ERROR] DOMAIN_NAME environment variable is missing." >&2
    exit 1
fi

# 2. Dynamic Configuration Injection
# We replace the placeholder in nginx.conf with your actual domain name
echo "[INFO] Configuring NGINX for domain: $DOMAIN_NAME"
sed -i "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf

# 3. SSL Certificate Generation
# We generate a self-signed certificate if it doesn't exist yet
CERTS_DIR="/etc/nginx/ssl"

if [ ! -f "$CERTS_DIR/$DOMAIN_NAME.crt" ]; then
    echo "[INFO] Generating self-signed SSL certificate..."
    
    mkdir -p "$CERTS_DIR"
    
    # Generate the key and certificate valid for 365 days
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERTS_DIR/$DOMAIN_NAME.key" \
        -out "$CERTS_DIR/$DOMAIN_NAME.crt" \
        -subj "/C=FR/ST=GrandEst/L=Mulhouse/O=42/OU=Inception/CN=$DOMAIN_NAME"
        
    echo "[INFO] SSL certificate generated successfully."
fi

# 4. Execute the command from CMD (PID 1)
exec "$@"
