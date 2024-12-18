#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IFS=$'\n'
PATTERN=""
CONTEXT=""
DEBUG=false

print_help() {
    cat << EOF
Set kubeconfig for devices from fleet and tailscale.
If no pattern is provided, all devices will be listed.

Usage: ${0} [OPTIONS] [PATTERN]

Options:
    -h, --help                        Show this help message and exit
    -k, --kubeconfig                  Kubeconfig context mode
    --debug                           Run with debug information

Examples:
    ./get-device-selection.sh         List all devices
    ./get-device-selection.sh -k      List all available contexts
    ./get-device-selection.sh lab     Search for devices containing 'lab'

Arguments:
    PATTERN       Optional pattern to filter output
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -k|--kubeconfig)
            CONTEXT="--kubeconfig"
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
            PATTERN="$PATTERN $1"
            shift
            ;;
    esac
done

if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

PATTERN=$(echo "$PATTERN" | xargs)

fleet_devices=$("$SCRIPT_DIR"/get-fleet-clusters.sh "$PATTERN")
tailscale_devices=$("$SCRIPT_DIR"/get-tailscale-devices.sh "$CONTEXT")

if [ -z "$PATTERN" ]; then
    FZF_QUERY=""
else
    FZF_QUERY="--query \"$PATTERN\""
fi

if command -v "fzf" > /dev/null 2>&1 ; then
    select_cmd="fzf --select-1 --exit-0 --exact $FZF_QUERY"
else
    read -rp "Search device: " device
    select_cmd="grep -i $device"
fi

echo "$tailscale_devices" | while IFS= read -r tailscale_device; do
    IFS=$' ' read -r name <<< "$tailscale_device"
    found=false
    while IFS= read -r fleet_device; do
        IFS=$' ' read -r group location mac <<< "$fleet_device"
        if [[ "$name" == *"$mac"* ]]; then
            echo "$tailscale_device $group $location"
            found=true
            break
        fi
    done <<< "$fleet_devices"
    if [[ "$found" == "false" ]]; then
        echo "$tailscale_device - -"
    fi
done | bash -c "$select_cmd"

