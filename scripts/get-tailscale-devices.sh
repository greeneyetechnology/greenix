#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IFS=$'\n'
KUBECONFIG=false

if ! command -v "tailscale" 2>&1 >/dev/null; then
    echo "error: 'tailscale' command not found."
    echo "https://tailscale.com/download"
    exit 1
fi

print_help() {
    cat << "EOF"
Usage: get-tailscale-devices.sh [options]

List Tailscale devices.

Options:
  -h, --help       Show this help message and exit
  -k, --kubeconfig Filter for kubeconfig compatible entries

For more information, visit: https://tailscale.com/
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -k|--kubeconfig)
            KUBECONFIG=true
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

if $KUBECONFIG; then
    tailscale status | awk '/tagged-devices/ {if($2 !~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) print $2, $NF}'
else
    tailscale status | awk '/tagged-devices/ {if($2 ~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/) print $2, $NF}'
fi

