#!/usr/bin/env bash
set -euo pipefail

SSH_CONFIG="$HOME/.ssh/config"

get_hosts() {
    local config_file="$1"
    [ -f "$config_file" ] || return 0

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        # Handle Include directives
        if [[ "$line" =~ ^[[:space:]]*Include[[:space:]]+(.*) ]]; then
            include_path="${BASH_REMATCH[1]}"
            # Expand path if it starts with ~
            include_path="${include_path/#\~/$HOME}"
            # Handle wildcards in include path
            for included_file in $include_path; do
                [ -f "$included_file" ] && get_hosts "$included_file"
            done
            continue
        fi

        # Extract Host entries
        if [[ "$line" =~ ^[[:space:]]*Host[[:space:]]+(.*) ]]; then
            host_pattern="${BASH_REMATCH[1]}"
            # Skip wildcard-only patterns
            [[ "$host_pattern" != "*" ]] && echo "$host_pattern"
        fi
    done <"$config_file"
}

selected_hosts=$(get_hosts "$SSH_CONFIG" | sort | fzf -m --bind ctrl-a:select-all)

if [ -z "${TMUX:-}" ]; then
    echo "error: not in a tmux session."
    exit 1
fi

tmux_session_name=$(tmux display-message -p '#S')
tmux new-window -t "$tmux_session_name" -n gssh
tmux_session_id=$(tmux display-message -p '#I')

host_count=$(echo "$selected_hosts" | wc -w)
for ((i = 1; i < host_count; i++)); do
    tmux split-window -t "$tmux_session_name":"$tmux_session_id"
    tmux select-layout tiled
done

i=1
for host in $selected_hosts; do
    tmux send-keys -t "$i" "clear && ssh '$host'" Enter
    ((i += 1))
done
