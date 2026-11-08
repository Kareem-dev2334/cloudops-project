#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 URL"
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

if [ ! -f "$script_dir/check-http.sh" ]; then
    echo "Missing helper: $script_dir/check-http.sh" >&2
    exit 1
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/cloudops"
log_file="${RETRY_LOG_FILE:-$state_dir/retry-check.log}"
mkdir -p -- "$(dirname -- "$log_file")" || exit 1

result=1

for attempt in 1 2 3; do
    echo "Attempt: $attempt"

    if check_output=$(bash "$script_dir/check-http.sh" "$1"); then
        printf '%s\n' "$check_output"
        echo "Service responded; stopping retries"
        result=0
        break
    else
        printf '%s\n' "$check_output"
        echo "Check failed"
        if [ "$attempt" -lt 3 ]; then
            sleep 2
        fi
    fi
done

echo "Final result: $result"
timing=$(printf '%s\n' "$check_output" | grep -E '^HTTP [0-9]{3} \| Total: [0-9.]+s$' | tail -n 1)
echo "[$(date '+%F %T')] URL: $1 | ${timing:-Timing unavailable} | Result: $result  Attempt: $attempt" >> "$log_file"
exit "$result"
