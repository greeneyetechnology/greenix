#!/usr/bin/env bash
set -euo pipefail

PATTERN="rt-versions"
BASE_DIR="$HOME"
DEPTH=5
PATTERN=""
DEBUG=false

print_help() {
    cat <<EOF
Find a directory path

Usage: $(basename "$0") [OPTIONS] [DIR]

Options:
    -b, --base-dir DIR                  Base directory to start search from (default: \$HOME)
    -d, --depth NUM                     Maximum search depth (default: 5)
    -h, --help                          Show this help message and exit
    --debug                             Run with debug information

Arguments:
    DIR                                 Directory to search for

Examples:
    $(basename "$0") rt-versions        # Search for rt-versions dir under \$HOME
    $(basename "$0") -b /tmp foo        # Search for foo dir under /tmp
    $(basename "$0") -d 3 -b /opt bar   # Search for bar dir under /opt with max depth 3
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        print_help
        exit 0
        ;;
    -b | --base-dir)
        BASE_DIR="$2"
        shift 2
        ;;
    -d | --depth)
        DEPTH="$2"
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
        PATTERN="$1"
        shift
        ;;
    esac
done

if [ "${DEBUG:-false}" = "true" ]; then
    set -x
fi

if [ -z "$PATTERN" ]; then
    echo "error: no search pattern provided."
    echo
    print_help
    exit 1
fi

excludes=(
    Library
    go
    .local
    .cargo
    .cache
    .npm
    node_modules
    .virtualenvs
    venv
    .venv
    __pycache__
    .pytest_cache
    .mypy_cache
    .pyenv
    target
    dist
    build
    out
)

if command -v fd &>/dev/null; then
    find_cmd="fd -1 -t d ${PATTERN} $(printf -- "--exclude %s " "${excludes[@]}") --max-depth $DEPTH $BASE_DIR"
else
    find_cmd="find $BASE_DIR -maxdepth $DEPTH -type d -name \"*${PATTERN}*\" $(printf -- "-not -path '*/%s/*' " "${excludes[@]}") -print -quit"
fi

path_found=$(bash -c "$find_cmd")
if [ -z "$path_found" ]; then
    echo "error: no directories matched ${PATTERN}."
    exit 1
fi

echo "${path_found%/}"
