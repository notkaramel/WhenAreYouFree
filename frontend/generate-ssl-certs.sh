#!/bin/bash

# Generate self-signed SSL certificates for local development/testing
# For production, use certificates from a trusted CA (Let's Encrypt, etc.)

DOMAIN="${1:-free.notkaramel.dev}"
CERT_DIR="./certs"
mkdir -p "$CERT_DIR"

echo "Generating SSL certificates for domain: $DOMAIN"

# Create OpenSSL config file with SAN extension
cat > "$CERT_DIR/openssl.cnf" <<EOF
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

# Generate self-signed certificate with SAN extensions
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$CERT_DIR/key.pem" \
  -out "$CERT_DIR/cert.pem" \
  -config "$CERT_DIR/openssl.cnf" \
  -extensions v3_req

# Clean up config file
rm "$CERT_DIR/openssl.cnf"

echo "SSL certificates generated in $CERT_DIR/"
echo "Certificate is valid for: $DOMAIN"
echo "To use these certificates, uncomment the volume mount in docker-compose-prod.yml:"
echo "  - ./frontend/certs:/etc/nginx/ssl:ro"

