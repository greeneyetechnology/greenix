#!/usr/bin/env bash
set -euo pipefail


export VAULT_ADDR="https://sod.tail6954.ts.net/"
KEY_PATH="${HOME}/.ssh/greeneye_id_ed25519"
CERT_PATH="${HOME}/.ssh/greeneye-cert.pub"

print_help() {
    cat << EOF
Usage: validate-certificate.sh [options]

Options:
    -k, --key-path <path>           Path to SSH private key (default: ~/.ssh/greeneye_id_ed25519)
    -c, --certificate-path <path>   Path to SSH certificate (default: ~/.ssh/greeneye-cert.pub)
    -v, --vault-address <url>       Vault server address (default: https://sod.tail6954.ts.net/)
    -h, --help                      Show this help message

This script validates and manages SSH certificates using HashiCorp Vault.
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -k|--key-path)
            KEY_PATH="$2"
            shift; shift
            ;;
        -c|--certificate-path)
            CERT_PATH="$2"
            shift; shift
            ;;
        -v|--vault-address)
            export VAULT_ADDR="$2"
            shift; shift
            ;;
        -h|--help)
            print_help
            ;;
        -*)
            echo "unknown option: $1" >&2
            return 1
            ;;
        *)
            # Collect non-option arguments for the query
            query+="$1 "
            shift
            ;;
    esac
done

if ! command -v "vault" 2>&1 >/dev/null; then
    echo "error: vault not found."
    echo "https://developer.hashicorp.com/vault/install"
    exit 1
fi

if ! vault token lookup 2>&1 >/dev/null; then
    echo "not logged in to vault."
    echo "attempting login..."
    if ! vault login -method=oidc; then
        echo "error: login failed."
        exit 1
    fi
fi

if ! date --version 2>&1 | grep -q "GNU coreutils"; then
    echo "error: command 'date' version not supported."
    echo "make sure you use the GNU date from 'coreutils' library."
    exit 1
fi

sign_certificate() {
    if ! vault write -field=signed_key ssh-client-signer/sign/administrator-role public_key=@"$KEY_PATH.pub" valid_principals=administrator > "$CERT_PATH"; then
        return 1
    fi
}

valid_certificate() {
    if [ ! "$CERT_PATH" ]; then
        echo "error: couldn't find certificate."
        return 1
    fi
    expire_date_timestamp=$(date -d "$(ssh-keygen -L -f "$CERT_PATH" | awk '/Valid/ {print $5}')" "+%s")
    current_date_timestamp=$(date "+%s")
    if [ $current_date_timestamp -gt $expire_date_timestamp ]; then
        echo "error: certificate expired"
        return 1
    fi
}

if ! [ -f "$KEY_PATH" ] || ! [ -f "$KEY_PATH.pub" ]; then
    echo "couldn't find ssh key to generate certificate."
    echo "attempting key generation..."
    if ! ssh-keygen -t ed25519 -f "$KEY_PATH"; then
        echo "error: failed to generate key."
        exit 1
    fi
    echo "key generated successfully at ${KEY_PATH}."
fi

if ! [ -f "$CERT_PATH" ]; then
    echo "couldn't find certificate."
    echo "signing certificate"
    sign_certificate
fi

if ! valid_certificate; then
    echo "certificate expired."
    echo "resigning certificate"
    if ! sign_certificate; then
        echo "error: failed to sign certificate"
        exit 1
    fi
else
    hours_left=$(( ($expire_date_timestamp - $current_date_timestamp) / 3600 ))
    echo "certificate is valid for another $hours_left hours"
fi