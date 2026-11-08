#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: bash check-http.sh URL"
  exit 2
fi

url="$1"

if curl --fail --silent --show-error --max-time 10 \
    --write-out '\nHTTP %{http_code} | Total: %{time_total}s\n' \
    "$url"; then
  echo
  echo "HTTP check passed"
  exit 0
else
  echo "HTTP check failed"
  exit 1
fi
