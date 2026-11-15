#!/bin/bash
set -e

compose() {
    sudo docker compose -p cloudops-release-lab "$@"
}

existing=$(compose ps -aq)
if [ -n "$existing" ]; then
    echo "Lab containers already exist; refusing to remove them" >&2
    exit 1
fi

cleanup() {
    status=$?
    if ! compose down; then
        echo "Compose cleanup failed" >&2
        if [ "$status" -eq 0 ]; then
            status=1
        fi
    fi
    exit "$status"
}

trap cleanup EXIT

compose up -d
bash scripts/health-checks/release-gate.sh \
    "${RELEASE_GATE_URL:-http://127.0.0.1:8080/health}"
