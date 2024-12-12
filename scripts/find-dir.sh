#!/usr/bin/env bash
set -euo pipefail


PATTERN="rt-versions"
BASE_DIR="$HOME"
DEPTH=5

print_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
    -p, --pattern PATTERN   Pattern to search for (default: rt-versions)
    -b, --base-dir DIR      Base directory to start search from (default: \$HOME)
    -d, --depth NUM         Maximum search depth (default: 5)
    -h, --help              Show this help message and exit
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -b|--base-dir)
            BASE_DIR="$2"
            shift 2
            ;;
        -d|--depth)
            DEPTH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            print_help
            ;;
    esac
done

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

if command -v fd &> /dev/null; then
    find_cmd="fd -1 -t d $PATTERN$ $(printf -- "--exclude %s " "${excludes[@]}") --max-depth $DEPTH "$BASE_DIR""
else
    find_cmd="find $BASE_DIR -maxdepth $DEPTH -type d -name $PATTERN $(printf -- "-not -path '*/%s/*' " "${excludes[@]}") -print -quit"
fi

path_found=$(bash -c "$find_cmd")
if [ -z "$path_found" ]; then
    echo "error: no directories matched $PATTERN."
    exit 1
fi

echo $path_found
