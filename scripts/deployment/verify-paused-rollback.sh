#!/bin/bash

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 EXPECTED_REV ACTUAL_REV DESIRED RUNNING PENDING ROLLOUT_STATE" >&2
    exit 2
fi

expected_revision="$1"
actual_revision="$2"
desired="$3"
running="$4"
pending="$5"
rollout_state="$6"
result=1

if [[ ! $expected_revision =~ ^[0-9]+$ ||
      ! $actual_revision =~ ^[0-9]+$ ||
      ! $desired =~ ^[0-9]+$ ||
      ! $running =~ ^[0-9]+$ ||
      ! $pending =~ ^[0-9]+$ ]]; then
    echo "Keep the change open: missing or invalid revision or task count" >&2
elif [ "$expected_revision" -ne "$actual_revision" ]; then
    echo "Keep the change open: expected revision $expected_revision, found $actual_revision" >&2
elif [ "$pending" -gt 0 ]; then
    echo "Keep the change open: $pending task(s) still pending" >&2
elif [ "$rollout_state" != "COMPLETED" ]; then
    echo "Keep the change open: rollout state is ${rollout_state:-unknown}" >&2
elif [ "$desired" -ne 0 ] || [ "$running" -ne 0 ]; then
    echo "Keep the change open: desired=$desired, running=$running" >&2
else
    echo "Rollback configuration verified; live recovery not tested"
    result=0
fi

exit "$result"
