#!/bin/bash
#
# Secret should have a full trust chain, in order, starting with the
# certificate, followed by any intermediate certificates, with the final
# certificate being the root CA.
#
# There is no validation to make sure your certs are in the right order,
# that's on you. If you're using cert-manager to pull from Let's Encrypt,
# your certificate chain is in the right order.

set -e

TLS_SECRET_NAME="$1"

# Pull cert/key
[[ -d "$TLS_SECRET_NAME" ]] || mkdir "$TLS_SECRET_NAME"
oc get secret "$TLS_SECRET_NAME" \
    -o jsonpath='{.data.tls\.crt}' \
    | base64 -d > "$TLS_SECRET_NAME/tls.crt"
oc get secret "$TLS_SECRET_NAME" \
    -o jsonpath='{.data.tls\.key}' \
    | base64 -d > "$TLS_SECRET_NAME/tls.key"

# Extract root CA - This is a hack, can't figure out a way with openssl :(
ROOT_CA_START_LINE=$(grep -n 'BEGIN CERTIFICATE' "$TLS_SECRET_NAME/tls.crt" \
                        | cut -f 1 -d ':' | tail -n 1)
sed -n "$ROOT_CA_START_LINE,\$p" \
    "$TLS_SECRET_NAME/tls.crt" > "$TLS_SECRET_NAME/ca.crt"

# Validate cert/key
KEY_VALIDATION_HASH=$(openssl rsa -in "./$TLS_SECRET_NAME/tls.key" -noout -modulus | openssl sha256)
CERT_VALIDATION_HASH=$(openssl x509 -in "./$TLS_SECRET_NAME/tls.crt" -noout -modulus | openssl sha256)
if [[ $CERT_VALIDATION_HASH = $KEY_VALIDATION_HASH ]] ; then
    echo "Cert/key modulus hashes match: $CERT_VALIDATION_HASH"
else
    >&2 echo "Cert/key modulus hashes DO NOT MATCH!"
    >&2 echo "./$TLS_SECRET_NAME/tls.crt: $CERT_VALIDATION_HASH"
    >&2 echo "./$TLS_SECRET_NAME/tls.key: $KEY_VALIDATION_HASH"
fi

# Print begin/end dates
openssl x509 -in "./$TLS_SECRET_NAME/tls.crt" -noout -dates
