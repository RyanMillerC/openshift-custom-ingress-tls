#!/bin/bash
#
# Secret should have a full trust chain, in order, starting with the
# certificate, followed by any intermediate certificates, with the final
# certificate being the root CA.
#
# There is no validation to make sure your certs are in the right order,
# that's on you. If you're using cert-manager to pull from Let's Encrypt,
# your certificate chain is in the right order.
#

set -e

TLS_SECRET_NAME="$1"
TLS_SECRET_NAMESPACE='certs'

# !! OUTPUT_DIR will be removed if it exists !!
OUTPUT_DIR="/home/ryan/tls/$TLS_SECRET_NAME"

CERT_PATH="${OUTPUT_DIR}/${TLS_SECRET_NAME}.crt"
KEY_PATH="${OUTPUT_DIR}/${TLS_SECRET_NAME}.key"
CA_PATH="${OUTPUT_DIR}/${TLS_SECRET_NAME}.ca"

# Validate secret exists
kubectl get secret "$TLS_SECRET_NAME" -n "$TLS_SECRET_NAMESPACE" || exit 1

[[ -d "$OUTPUT_DIR" ]] && rm -rf "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR"

# Pull cert/key
kubectl get secret "$TLS_SECRET_NAME" \
    -n "$TLS_SECRET_NAMESPACE" \
    -o jsonpath='{.data.tls\.crt}' \
    | base64 -d > "$CERT_PATH"
kubectl get secret "$TLS_SECRET_NAME" \
    -n "$TLS_SECRET_NAMESPACE" \
    -o jsonpath='{.data.tls\.key}' \
    | base64 -d > "$KEY_PATH"

# Extract root CA - This is a hack, can't figure out a way with openssl :(
ROOT_CA_START_LINE=$(grep -n 'BEGIN CERTIFICATE' "$CERT_PATH" \
                        | cut -f 1 -d ':' | tail -n 1)
sed -n "$ROOT_CA_START_LINE,\$p" \
    "$CERT_PATH" > "$CA_PATH"

# Validate cert/key
KEY_VALIDATION_HASH=$(openssl rsa -in "$KEY_PATH" -noout -modulus | openssl sha256)
CERT_VALIDATION_HASH=$(openssl x509 -in "$CERT_PATH" -noout -modulus | openssl sha256)
if [[ $CERT_VALIDATION_HASH = $KEY_VALIDATION_HASH ]] ; then
    echo "Cert/key modulus hashes match: $CERT_VALIDATION_HASH"
else
    >&2 echo 'Cert/key modulus hashes DO NOT MATCH!'
    >&2 echo "$CERT_PATH: $CERT_VALIDATION_HASH"
    >&2 echo "$KEY_PATH: $KEY_VALIDATION_HASH"
fi

# Print begin/end dates
openssl x509 -in "$CERT_PATH" -noout -dates
