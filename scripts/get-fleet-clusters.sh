#!/usr/bin/env bash
set -euo pipefail


SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
FLEET_PATH=$($SCRIPT_DIR/find-dir.sh --pattern "rt-versions")clusters
CONFIGMAP_NAME="cluster-vars-cm.yaml"
PATTERN="office"

print_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -p, --pattern     Search pattern for filtering clusters (default: 'office')
  -c, --configmap   Configmap file that holds the locations (default: 'cluster-vars-cm.yaml')
  -h, --help        Display this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -c|--configmap)
            CONFIGMAP_NAME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            ;;
    esac
done

if ! [ -d $FLEET_PATH ]; then
    echo "error: path not found $FLEET_PATH"
fi

cluster_cmd="awk -F': ' '/CLUSTER|SPRAYER_GROUP|BOOM_LOCATION/ {split(\$2, arr, \"#\"); printf \"%s \", arr[1]} END {print \"\"}' {}"

if command -v "fd" 2>&1 >/dev/null; then
    find_cmd="fd -t f $CONFIGMAP_NAME $FLEET_PATH --exec $cluster_cmd"
else
    find_cmd="find $FLEET_PATH -type f -name $CONFIGMAP_NAME -exec $cluster_cmd \;"
fi

if command -v "rg" 2>&1 >/dev/null; then
    bash -c "$find_cmd" | rg "$PATTERN"
else
    bash -c "$find_cmd" | grep "$PATTERN"
fi
