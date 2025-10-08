#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"   # cd into kafka/security

PASSWORD=changeit
DAYS=365
BROKERS=("kafka1" "kafka2" "kafka3")
HOST_IP="127.0.0.1"    # for host-based testing; keep localhost in SAN

# --- 2.1 Create a local Certificate Authority (CA) ---
if [[ ! -f ca/ca-key.pem ]]; then
  openssl req -new -x509 -days $DAYS \
    -keyout ca/ca-key.pem -out ca/ca-cert.pem \
    -passout pass:$PASSWORD -subj "/CN=Kafka-Local-CA"
  echo "Created CA in kafka/security/ca"
fi

# --- 2.2 For each broker: keystore, CSR, signed cert, truststore ---
for b in "${BROKERS[@]}"; do
  echo "=== Generating for ${b} ==="
  OUTDIR="${b}"
  mkdir -p "${OUTDIR}"

  # Keystore with keypair
  keytool -genkey -noprompt \
    -alias "${b}" \
    -dname "CN=${b}, OU=Dev, O=Local, L=Local, S=Local, C=US" \
    -keystore "${OUTDIR}/kafka.server.keystore.jks" \
    -storepass "$PASSWORD" -keypass "$PASSWORD" \
    -keyalg RSA

  # CSR
  keytool -certreq -noprompt \
    -alias "${b}" \
    -keystore "${OUTDIR}/kafka.server.keystore.jks" \
    -storepass "$PASSWORD" -keypass "$PASSWORD" \
    -file "${OUTDIR}/kafka.server.csr"

  # Sign CSR with CA (include SAN for hostname + localhost)
  openssl x509 -req -in "${OUTDIR}/kafka.server.csr" \
    -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial \
    -out "${OUTDIR}/kafka.server.crt" -days $DAYS \
    -passin pass:$PASSWORD \
    -extfile <(printf "subjectAltName=DNS:%s,IP:%s\n" "${b}" "$HOST_IP")

  # Import CA then server cert to keystore
  keytool -import -noprompt \
    -alias CARoot \
    -file ca/ca-cert.pem \
    -keystore "${OUTDIR}/kafka.server.keystore.jks" \
    -storepass "$PASSWORD"

  keytool -import -noprompt \
    -alias "${b}" \
    -file "${OUTDIR}/kafka.server.crt" \
    -keystore "${OUTDIR}/kafka.server.keystore.jks" \
    -storepass "$PASSWORD"

  # Truststore (trust our CA)
  keytool -import -noprompt \
    -alias CARoot \
    -file ca/ca-cert.pem \
    -keystore "${OUTDIR}/kafka.server.truststore.jks" \
    -storepass "$PASSWORD"

  chmod 644 "${OUTDIR}"/* || true
done

echo "All broker keystores/truststores created."
