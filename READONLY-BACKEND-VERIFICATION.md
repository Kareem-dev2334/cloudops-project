# Read-only Backend Verification

Date: 25 October 2026
Region: ap-southeast-2
Task definition: cloudops-task:5
Backend image tag: 47bd7df

## Configuration

The backend uses a read-only root filesystem with writable tmpfs mounts:
- /tmp: 16 MiB.
- /home/appuser: 4 MiB, owned by UID/GID 10001.

## Verification

Local container checks and all 12 security tests passed under these
restrictions. CI checks passed and were merged in PR #22.

Standalone Fargate task:
ca565f1b137448c9b0e4b87b4bbcfbaf

The task verified:
- Backend ran as UID 10001.
- Root filesystem was read-only.
- Both temporary mounts were writable.
- Nginx forwarded /health to Gunicorn and returned HTTP 200.
- Unauthenticated /api/users returned HTTP 401.
- Gunicorn shut down with exit code 0.

Both containers stopped with exit code 0.

## Final service state

The service remained on cloudops-task:4 with 0 desired, 0 running,
and 0 pending tasks.

## Normal startup and shutdown

A second standalone task used revision 5 without command overrides:
5914cd404dda4ed7aaf8ca5a8c456aa6

Both containers reached RUNNING. Backend logs confirmed Gunicorn
started as PID 1, booted its worker, and created its control socket.

After an ECS stop-task request, Gunicorn logged receipt of SIGTERM
and orderly worker/master shutdown. Both containers stopped with
exit code 0.

No HTTP requests were tested during this second task.

## Real S3 upload check

Standalone revision 5 task:
0771819289e447ca8bfe51a6db35bb1f

The check confirmed UID 10001 and a read-only root filesystem.
Using Flask's internal test client and injected authentication token,
it uploaded a generated 2x2 PNG through /upload to real S3.

The object was downloaded and its bytes matched the original image.
The test object was then deleted.

Observed logs:
- PASS: authenticated upload and S3 read-back under read-only root
- PASS: test object deleted

Both containers stopped with exit code 0.
This check did not send the upload through Nginx or Gunicorn.

## Limits

The first task used a Python command override to launch Gunicorn
and verify internal HTTP responses. The second task verified normal
startup and ECS-triggered shutdown without command overrides.

Public HTTP, TLS, and load balancing were not tested in these checks.

Real RDS queries were not tested under the read-only configuration.
Revision 5 has not been deployed to the service.
