#!/bin/bash

if [ "$#" -ne 1 ]; then
echo "Usage: $0 LOG_FILE" >&2
exit 2
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/cloudops"
summary_file="${SUMMARY_LOG_FILE:-$state_dir/retry-summary.log}"
mkdir -p -- "$(dirname -- "$summary_file")" || exit 1

log_file="$1"

if [ -f "$log_file" ]; then
    echo "Log found"
else
    echo "Log missing: $log_file" >&2
exit 1
fi

result_count=$(grep -c "Result: 1" "$log_file")
success_count=$(grep -c "Result: 0" "$log_file")
recovered_count=$(grep -Ec 'Result: 0 +Attempt: [23][[:space:]]*$' "$log_file")
total_count=$((result_count + success_count))

if [ "$total_count" -gt 0 ]; then
    failure_percent="$((result_count * 100 / total_count))%"
if [ "$((result_count * 2))" -ge "$total_count" ]; then
    echo "Warning: high failure rate"
fi

else
    failure_percent="N/A"
fi

echo "$(date '+%F %T') Total: $total_count | Passed: $success_count | Failed: $result_count Source: $log_file | Failure rate: $failure_percent | Passed after retry: $recovered_count" >> "$summary_file"
