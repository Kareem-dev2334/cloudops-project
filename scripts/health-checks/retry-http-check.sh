#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 URL"
    exit 2
fi

result=1

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

if [ ! -f "$script_dir/check-http.sh" ]; then
    echo "Missing helper: $script_dir/check-http.sh" >&2
    exit 1
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/cloudops"
log_file="${RETRY_LOG_FILE:-$state_dir/retry-check.log}"
mkdir -p -- "$(dirname -- "$log_file")" || exit 1

for attempt in 1 2 3; do
    echo "Attempt: $attempt"

        if bash "$script_dir/check-http.sh" "$1"; then
        echo "Service responded; stopping retries"
        result=0
        break
    else
        echo "Check failed"
        if [ "$attempt" -lt 3 ]; then
            sleep 2
        fi
    fi
done

echo "Final result: $result"
echo "[$(date '+%F %T')] URL: $1 Result: $result  Attempt: $attempt " >> "$log_file"
exit "$result"
