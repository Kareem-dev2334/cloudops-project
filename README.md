# CloudOps

A learning and portfolio project combining an Nginx frontend,
a Flask backend, MySQL access, S3 image uploads, Terraform,
and GitHub Actions CI.

## Application architecture

Nginx serves the static frontend on port 80 and proxies API
requests to Flask on port 5000. The default configuration uses
`cloudops-backend:5000`; the ECS configuration uses `127.0.0.1:5000`.

| Request to Nginx | Backend route | Purpose |
|---|---|---|
| `/` | Not proxied | Static HTML portal |
| `/api/` | `/` | Backend online message |
| `/api/users` | `/users` | Query MySQL users |
| `/api/upload` | `/upload` | Authenticated image upload to S3 |
| `/health` | `/health` | Basic Flask health response |

The `/api/` prefix is removed before forwarding to Flask.
With the default configuration, the backend hostname must resolve
from the Nginx container.

The frontend currently makes no API calls. Its status and
hosting labels are static text, not monitoring results.

## Backend configuration

| Environment variable | Purpose |
|---|---|
| `DB_HOST` | MySQL hostname |
| `DB_USER` | MySQL username |
| `DB_PASSWORD` | MySQL password |
| `DB_NAME` | Database name |
| `DB_PORT` | MySQL port; defaults to 3306 |
| `UPLOAD_API_TOKEN` | Expected bearer token for uploads |
| `USERS_API_TOKEN` | Expected bearer token for reading users |
| `AWS_DEFAULT_REGION` | AWS SDK region, such as ap-southeast-2 |
| `S3_BUCKET` | Destination bucket for image uploads |

The `/users` route expects a `users` table containing
`id`, `name`, `email`, and `created_at`.

`GET /api/users` requires an `Authorization: Bearer <USERS_API_TOKEN>`
header. Missing or invalid tokens return 401; missing server token
configuration returns 503.

The S3 bucket name comes from the `S3_BUCKET` environment variable.
Boto3 obtains credentials through its standard credential
provider chain. Use an appropriate IAM role for AWS workloads.
Never commit credentials, tokens, or `.env` secrets.

### Backend server

The backend Docker image serves Flask through Gunicorn on port 5000,
using one synchronous worker. Access logs go to stdout and error logs
go to stderr. The image runs as appuser (UID/GID 10001).

ECS task revision 5 configures the backend with a read-only root
filesystem and writable tmpfs mounts at /tmp (16 MiB) and
/home/appuser (4 MiB).

Verification covered all 12 security tests locally and in CI,
normal Gunicorn startup and shutdown on Fargate, and real S3 uploads
and RDS queries through Flask's internal test client.

Live service checks confirmed the portal loaded, /health returned
200, and unauthenticated /api/users returned 401 through Nginx.

After testing on 26 October 2026, the service remained configured
for revision 5 with zero desired, running, and pending tasks.

Running `python app.py` directly starts Flask's development server.

See [read-only backend verification](READONLY-BACKEND-VERIFICATION.md)
for evidence and test limitations.

## Upload controls

`POST /api/upload` expects:

- `Authorization: Bearer <token>`
- A multipart form field named `file`
- A valid JPEG or PNG image

The backend verifies image content with Pillow and generates
a UUID-based S3 object key.

The total HTTP request body is limited to 5 MiB, including
multipart overhead.

Uploads require S3_BUCKET to contain the destination bucket name.
After authentication, missing or blank bucket configuration returns
HTTP 503 with {"error":"Storage not configured"}.

Local tests verify the configured bucket is passed to the mocked S3
upload call. A revision 5 Fargate check also verified a real upload,
matching-byte read-back, and deletion of the test object.

## Containers

- `Dockerfile`: Nginx frontend using `nginx:latest`
- `Dockerfile.backend`: Python 3.13 slim backend
- Backend startup: Gunicorn serving `app:app` on port 5000
- Python dependencies are pinned in `requirements.txt`

Build locally from the repository root:

```bash
docker build -f Dockerfile -t cloudops-web:local .
docker build -f Dockerfile.backend -t cloudops-backend:local .
```

These commands build images; they do not deploy AWS resources.

For ECS Fargate, where both containers share one task using
`awsvpc` networking, build the frontend with:

```bash
docker build -f Dockerfile \
  --build-arg NGINX_CONFIG=default.ecs.conf \
  -t cloudops-web:ecs .
```

The default configuration reaches Flask at `cloudops-backend:5000`.
The ECS configuration uses `127.0.0.1:5000` within the shared task.

CI builds both frontend variants and checks the ECS Nginx
configuration syntax.

## Terraform

The verified VPC configuration is in `terraform-vpc-lab/`,
using AWS region `ap-southeast-2`.

It includes:

- VPC: 10.0.0.0/16
- Public subnet: 10.0.1.0/24
- Private subnet: 10.0.2.0/24
- Internet Gateway
- Public and private route tables and subnet associations
- Existing backend security group lookup
- Database security group
- Backend-to-database TCP 3306 rules

The public route table has a default route to the Internet
Gateway. The private route table has no internet default route.

A separate `terraform/` directory also exists. Its purpose
and deployment instructions have not yet been reviewed here.

Terraform state files are excluded from Git. The provider
lock file is committed.

## Continuous integration

Workflow: `.github/workflows/ci.yml`

Runs on pushes to `main` and pull requests targeting `main`.

Required checks:

- `backend-check`: Python syntax, backend security tests,
  and both Docker image builds
- `Terraform checks`: formatting, provider initialisation
  without the backend, and configuration validation


Both jobs use Ubuntu 24.04. Terraform is pinned to 1.16.5.
The workflow does not run Terraform plan, apply, or destroy.

Backend tests and the backend Docker image both use Python 3.13.

See [CI verification evidence](CI-VERIFICATION.md) for
successful checks and the deliberate formatting failure test.

## Current limitations


- TLS and load balancing remain untested.
- Authenticated S3 and RDS checks used Flask's internal test client,
  rather than the public Nginx/Gunicorn path.
- `/health` does not check MySQL or S3 connectivity.
- The frontend contains a `<tittle>` typo.
- The frontend base image uses the mutable `latest` tag.
- Local startup, database schema setup, and AWS deployment
  instructions still need verification.
- Passing CI does not prove production readiness, live service
  connectivity, or infrastructure security.

## AWS cost control

Prefer local builds and CI checks for development.

Before creating, applying changes to, or destroying AWS
resources, review the proposed changes, costs, dependencies,
and cleanup steps.

Avoid unnecessary running compute, NAT Gateways, and load
balancers. Existing AWS resources can continue to incur costs
even when CI makes no infrastructure changes.
