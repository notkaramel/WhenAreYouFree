#!/bin/sh

# Get domain from environment variable or use default
DOMAIN="${SSL_DOMAIN:-free.notkaramel.dev}"

# Generate self-signed SSL certificates if real certificates don't exist
if [ ! -f /etc/nginx/ssl/domain.cert.pem ] || [ ! -f /etc/nginx/ssl/private.key.pem ]; then
    echo "SSL certificates not found. Generating self-signed certificates for domain: $DOMAIN..."
    
    # Create OpenSSL config file with SAN extension
    cat > /tmp/openssl.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Organization
CN = $DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/private.key.pem \
        -out /etc/nginx/ssl/domain.cert.pem \
        -config /tmp/openssl.cnf \
        -extensions v3_req
    
    rm /tmp/openssl.cnf
    echo "Self-signed certificates generated for $DOMAIN. For production, mount real certificates from a volume."
fi

# Start Nuxt app in the background
node .output/server/index.mjs &

# Start nginx in the foreground (this will keep the container running)
exec nginx -g "daemon off;"

