#!/bin/bash
set -e

CERT_DIR="/etc/nginx/ssl"
CERT="${CERT_DIR}/inception.crt"
KEY="${CERT_DIR}/inception.key"

# Generate self-signed cert if it doesn't exist yet
if [ ! -f "${CERT}" ]; then
    mkdir -p "${CERT_DIR}"

    openssl req -x509 -nodes \
        -newkey rsa:2048 \
        -keyout "${KEY}" \
        -out "${CERT}" \
        -days 365 \
        -subj "/C=NL/ST=Noord-Holland/L=Amsterdam/O=42/CN=${DOMAIN_NAME}"

    sed -e "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" \
        -e "s/\${WP_PORT}/${WP_PORT}/g" \
        /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
fi

# Start nginx in foreground as PID 1
exec nginx -g "daemon off;"