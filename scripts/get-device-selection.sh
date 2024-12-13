#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IFS=$'\n'

print_help() {
    cat << EOF
Usage: ${0} [options] [pattern]

Set kubeconfig for devices from fleet and tailscale.
If no pattern is provided, all devices will be listed.

Options:
  -h, --help                        Show this help message and exit
  -k, --kubeconfig                  Kubeconfig context mode

Examples:
  ./get-device-selection.sh         List all devices
  ./get-device-selection.sh -k      List all available contexts
  ./get-device-selection.sh lab     Search for devices containing 'lab'
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -k|--kubeconfig)
            KUBECTX="--kubeconfig"
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

PATTERN="${query:-${@}}"
if [ -z $PATTERN ]; then PATTERN="."; FZF_QUERY=""; else FZF_QUERY="--query $PATTERN"; fi
KUBECTX=${KUBECTX:-""}

fleet_devices=$($SCRIPT_DIR/get-fleet-clusters.sh --pattern $PATTERN)
tailscale_devices=$($SCRIPT_DIR/get-tailscale-devices.sh $KUBECTX)

if command -v "fzf" 2>&1 >/dev/null; then
    select_cmd="fzf --select-1 --exit-0 --exact "$FZF_QUERY""
else
    read -p "Search device: " device
    select_cmd="grep -i $device"
fi

echo "$tailscale_devices" | while IFS= read -r tailscale_device; do
    IFS=$' ' read -r name status <<< "$tailscale_device"
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

