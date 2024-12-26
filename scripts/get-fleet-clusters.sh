#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
FLEET_PATH=$("$SCRIPT_DIR"/find-dir.sh "rt-versions$")
CLUSTERS_PATH="$FLEET_PATH/clusters"
CONFIGMAP_NAME="cluster-vars-cm.yaml"
UPDATE_REPO=false
PATTERN=""

print_help() {
    cat <<EOF
List the clusters available from fleet management

Usage: $(basename "$0") [OPTIONS] [PATTERN]

Options:
    -c, --configmap     Configmap file that holds the locations (default: 'cluster-vars-cm.yaml')
    -f, --fleet-path    Fleet repository local path (default: 'rt-versions')
    -u, --update        Update your fleet repository
    -h, --help          Display this help message
    --debug             Run with debug information
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
    -f | --fleet-path)
        FLEET_PATH=$("$SCRIPT_DIR"/find-dir.sh "$FLEET_PATH$")
        shift 2
        ;;
    -u | --update)
        UPDATE_REPO=true
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

if [ -z "$PATTERN" ]; then
    PATTERN="."
fi

if ! [ -d "$CLUSTERS_PATH" ]; then
    echo "error: path not found $CLUSTERS_PATH."
fi

if $UPDATE_REPO; then
    git -C "$FLEET_PATH" fetch origin HEAD
    MAIN_BRANCH=$(git -C "$FLEET_PATH" remote show origin | sed -n '/HEAD branch/s/.*: //p')
    git -C "$FLEET_PATH" checkout "$MAIN_BRANCH"
    git -C "$FLEET_PATH" pull
    echo "Updated $FLEET_PATH."
    exit 0
fi

PATTERN=$(echo "$PATTERN" | xargs)

cluster_cmd="awk -F': ' '/CLUSTER|SPRAYER_GROUP|BOOM_LOCATION/ {split(\$2, arr, \"#\"); gsub(/[[:space:]]/, \"\", arr[1]); printf \"%s \", arr[1]} END {print \"\"}' {}"

if command -v "fd" >/dev/null 2>&1; then
    find_cmd="fd -t f $CONFIGMAP_NAME $CLUSTERS_PATH --exec $cluster_cmd"
else
    find_cmd="find $CLUSTERS_PATH -type f -name $CONFIGMAP_NAME -exec $cluster_cmd \;"
fi

if command -v "rg" >/dev/null 2>&1; then
    bash -c "$find_cmd" | awk '{print $3, $1, $2}' | rg "$PATTERN" | sort
else
    bash -c "$find_cmd" | awk '{print $3, $1, $2}' | grep "$PATTERN" | sort
fi
