#!/usr/bin/env bash
set -euo pipefail


IFS=$'\n'
K3S=false

print_help() {
    cat << "EOF"
List Tailscale devices.

Usage: get-tailscale-devices.sh [OPTIONS]

Options:
    -h, --help    Show this help message and exit
    -k, --k3s     Filter for k3s tagged entries
    --debug       run with debug information
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -k|--kubeconfig)
            K3S=true
            shift
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
            # Collect non-option arguments for the query
            query+="$1 "
            shift
            ;;
    esac
done

if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

if ! command -v "tailscale" > /dev/null 2>&1;  then
    echo "error: 'tailscale' command not found."
    echo "https://tailscale.com/download"
    exit 1
fi

if $K3S; then
    tailscale status | awk '/tagged-devices/ {if($2 !~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) print $2, $NF}'
else
    tailscale status | awk '/tagged-devices/ {if($2 ~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) print $2, $NF}'
fi

