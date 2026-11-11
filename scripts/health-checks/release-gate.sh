#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 URL" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

if bash "$script_dir/retry-http-check.sh" "$1"; then
    echo "Release accepted: health check passed"
else
    status=$?
    echo "Release rejected: health check failed (exit $status)" >&2
    exit "$status"
fi
