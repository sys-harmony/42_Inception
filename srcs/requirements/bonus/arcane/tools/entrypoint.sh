#!/bin/sh

# Load secrets into environment variables
export ENCRYPTION_KEY=$(cat /run/secrets/arc_encryption_key)
export JWT_SECRET=$(cat /run/secrets/arc_jwt_secret)

# Execute the binary
exec arcane
