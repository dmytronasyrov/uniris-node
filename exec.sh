#!/usr/bin/env bash

print_usage() {
  printf "Usage: sh exec.sh -h myhost -n node1 -s seed1 -p 3006 -r 80 -t 443"
  printf "-h - host name"
  printf "-n - node name"
  printf "-p - p2p port"
  printf "-r - REST port"
  printf "-s - seed name"
  printf "-t - REST TLS port"
}

HOSTNAME='localhost'
NODENAME='node'
PEER_PORT=3005
REST_PORT=80
SEED='seed'
REST_TLS_PORT=443


while getopts 'h:n:p:r:s:t:' flag; do
  case "${flag}" in
    h) HOSTNAME="${OPTARG}" ;;
    n) NODENAME="${OPTARG}" ;;
    p) PEER_PORT="${OPTARG}" ;;
    r) REST_PORT="${OPTARG}" ;;
    s) SEED="${OPTARG}" ;;
    t) REST_TLS_PORT="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

TLS_REL_DIR=_build/prod/rel/server/bin/tls
TLS_DIR="$(cd "$(dirname "$TLS_REL_DIR")"; pwd)/$(basename "$TLS_REL_DIR")"

rm -rf "$TLS_DIR"
mkdir "$TLS_DIR"
cp ./tls/cert.cnf "$TLS_DIR"

openssl req -new -sha256 -nodes -out "$TLS_DIR/server.csr" -newkey rsa:2048 -keyout "$TLS_DIR/server.key" -config "$TLS_DIR/cert.cnf"
openssl genrsa -passout pass:1111 -des3 -out "$TLS_DIR/ca.key" 4096
openssl req -passin pass:1111 -new -x509 -days 365 -key "$TLS_DIR/ca.key" -out "$TLS_DIR/ca.crt" -subj "/CN=TLS_SERVER"
openssl x509 -req -passin pass:1111 -days 365 -in "$TLS_DIR/server.csr" -CA "$TLS_DIR/ca.crt" -CAkey "$TLS_DIR/ca.key" -set_serial 01 -out "$TLS_DIR/server.crt" -extensions v3_ca -extfile "$TLS_DIR/cert.cnf"
openssl pkcs8 -topk8 -nocrypt -passin pass:1111 -in "$TLS_DIR/server.key" -out "$TLS_DIR/server.pem"

rm "$TLS_DIR/cert.cnf"
rm "$TLS_DIR/ca.key"
rm "$TLS_DIR/server.key"
rm "$TLS_DIR/server.csr"

export REPLACE_OS_VARS=true
export HOSTNAME=$HOSTNAME
export NODENAME=$NODENAME
export UNIRIS_P2P_PORT=$PEER_PORT
export UNIRIS_CRYPTO_SEED=$SEED
export REST_PORT=$REST_PORT
export REST_TLS_PORT=$REST_TLS_PORT
export UNIRIS_WEB_SSL_KEY_PATH="$TLS_DIR/server.pem"
export UNIRIS_WEB_SSL_CERT_PATH="$TLS_DIR/server.crt"

sh _build/prod/rel/server/bin/server foreground