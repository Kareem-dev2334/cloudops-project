# CloudOps health-check tools

These Bash scripts check an HTTP endpoint, retry failed checks, and summarize the results. They require Bash and curl. Docker Compose is only needed to run the local CloudOps example below.

## Run a local health check

From the repository root:

```bash
sudo docker compose up -d
bash scripts/health-checks/retry-http-check.sh "http://127.0.0.1:8080/health"
echo "Retry exit code: $?"
```

The retry script makes up to three attempts. It waits two seconds between failed attempts and stops as soon as a check succeeds. Each completed run records one final result, even if it took three attempts.

| Exit code | Meaning |
|---|---|
| `0` | A health check succeeded. |
| `1` | All attempts failed, or the script could not complete setup (for example, the helper script was missing). |
| `2` | The script was called without exactly one URL argument. |

## Summarize the results

```bash
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/cloudops"
bash scripts/health-checks/summarize-retries.sh "$state_dir/retry-check.log"
tail -n 1 "$state_dir/retry-summary.log"
```

The summary reports total, passed, and failed runs, plus the failure rate. It prints a warning when at least half the recorded runs failed. That warning describes the log’s history; the latest health check may have passed. An empty log shows `N/A` for the failure rate.

## Log locations

By default, both logs are stored outside the repository, under `$XDG_STATE_HOME/cloudops` if `XDG_STATE_HOME` is set and nonempty, or under `$HOME/.local/state/cloudops` otherwise.

| Log | Contents | Output path override |
|---|---|---|
| `retry-check.log` | One final result per completed retry run | `RETRY_LOG_FILE` |
| `retry-summary.log` | Timestamped summaries of the supplied input log | `SUMMARY_LOG_FILE` |

If you override `RETRY_LOG_FILE`, pass that same path as the input to `summarize-retries.sh`.

## Clean up the local stack

```bash
sudo docker compose down
sudo docker compose ps -a
```
