#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
IFS=$'\n'

print_help() {
    cat <<EOF
Generate SSH config file for Greeneye fleet devices.

Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help              Show this help message and exit
    -F, --config-path PATH  Set SSH config file path (default: ~/.ssh/greeneeye_config)
    -i, --identity FILE     Set SSH identity file path (default: ~/.ssh/greeneye_id_ed_25519)
    -u, --user USER         Set SSH user (default: yarok)
    --debug                 Run with debug information
EOF
}

SSH_CONFIG_PATH="$HOME/.ssh/greeneye_config"
SSH_IDENTITY_FILE="$HOME/.ssh/greeneye_id_ed25519"
SSH_CERTIFICATE_FILE="$HOME/.ssh/greeneye_id_ed25519-cert.pub"
SSH_USER="yarok"

while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        print_help
        exit 0
        ;;
    -F | --config-path)
        SSH_CONFIG_PATH="$2"
        shift 2
        ;;
    -i | --identity)
        SSH_IDENTITY_FILE="$2"
        shift 2
        ;;
    -u | --user)
        SSH_USER="$2"
        shift 2
        ;;
    --debug)
        DEBUG=true
        shift
        ;;
    -*)
        echo "Unknown option: $1"
        print_help
        exit 1
        ;;
    *)
        shift
        ;;
    esac
done

if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

fleet_devices=$("$SCRIPT_DIR"/get-fleet-clusters.sh)

while IFS= read -r fleet_device; do
    IFS=$' ' read -r group location mac <<<"$fleet_device"
    if [ "$group" == "spare" ]; then
        host="$mac"
    else
        host="$group-$location"
    fi
    cat <<EOF
Host $host
    User $SSH_USER
    HostName $mac
    IdentityFile $SSH_IDENTITY_FILE
    CertificateFile $SSH_CERTIFICATE_FILE
EOF
done <<<"$fleet_devices" >"$SSH_CONFIG_PATH"
