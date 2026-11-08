# Local CloudOps outage runbook

Use this when the local `/health` endpoint is unreachable or returns an error.

## First checks

Run these from the repository root:

```bash
sudo docker compose ps -a
curl -v --fail --max-time 5 "http://127.0.0.1:8080/health"
echo "curl exit code: $?"
sudo docker compose logs --tail=20 web
```

| Result | What it means |
|---|---|
| Exit `7` | Curl couldn’t connect to `127.0.0.1:8080`. Check whether the `web` container is running and publishing that port. |
| Exit `22` with HTTP `502` | Curl reached Nginx, which returned `502 Bad Gateway`. With `--fail`, curl treated that response as an error. The Nginx log said `No route to host ... while connecting to upstream`, pointing to the connection between Nginx and the backend. |
| Exit `28` | Curl hit its time limit. In our lab it received no HTTP response before the deadline, so the timeout alone didn’t tell us where the request stalled. |


## Recover from a stopped backend

If `docker compose ps -a` shows `cloudops-backend` is stopped and `web` is still running, start only the backend:

```bash
sudo docker compose up -d cloudops-backend
bash scripts/health-checks/retry-http-check.sh "http://127.0.0.1:8080/health"
echo "Recovery exit code: $?"
```

Confirm that `/health` returns `{"status":"healthy"}` and the retry script exits `0`.

## Other failure paths

- **Exit `7`:** Check `sudo docker compose ps -a` for the `web` container and its port mapping. If the local stack is stopped and should be running, use `sudo docker compose up -d`, then verify `/health`.
- **Exit `28`:** Check the verbose curl output for `Connected to`. If curl connected but received no response, inspect both services’ logs around the request time before restarting anything: `sudo docker compose logs --tail=20 web cloudops-backend`.

## Lab cleanup

After the local lab, remove the stack and verify that no project containers remain:

```bash
sudo docker compose down
sudo docker compose ps -a
```

The final table should have no container rows.
