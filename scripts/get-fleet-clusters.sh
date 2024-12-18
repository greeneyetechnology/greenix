#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
FLEET_PATH=$("$SCRIPT_DIR"/find-dir.sh "rt-versions")/clusters
CONFIGMAP_NAME="cluster-vars-cm.yaml"
PATTERN=""

print_help() {
    cat <<EOF
List the clusters available from fleet management

Usage: $(basename "$0") [OPTIONS] [PATTERN]

Options:
    -c, --configmap   Configmap file that holds the locations (default: 'cluster-vars-cm.yaml')
    -h, --help        Display this help message
    --debug           Run with debug information
Arguments:
    PATTERN       Optional pattern to filter available devices
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        print_help
        exit 0
        ;;
    -c | --configmap)
        CONFIGMAP_NAME="$2"
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
        PATTERN="$PATTERN $1"
        shift
        ;;
    esac
done

if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

if [ -z "$PATTERN" ]; then
    PATTERN="."
fi

if ! [ -d "$FLEET_PATH" ]; then
    echo "error: path not found $FLEET_PATH."
fi

PATTERN=$(echo "$PATTERN" | xargs)

cluster_cmd="awk -F': ' '/CLUSTER|SPRAYER_GROUP|BOOM_LOCATION/ {split(\$2, arr, \"#\"); gsub(/[[:space:]]/, \"\", arr[1]); printf \"%s \", arr[1]} END {print \"\"}' {}"

if command -v "fd" >/dev/null 2>&1; then
    find_cmd="fd -t f $CONFIGMAP_NAME $FLEET_PATH --exec $cluster_cmd"
else
    find_cmd="find $FLEET_PATH -type f -name $CONFIGMAP_NAME -exec $cluster_cmd \;"
fi

if command -v "rg" >/dev/null 2>&1; then
    bash -c "$find_cmd" | awk '{print $3, $1, $2}' | rg "$PATTERN" | sort
else
    bash -c "$find_cmd" | awk '{print $3, $1, $2}' | grep "$PATTERN" | sort
fi
