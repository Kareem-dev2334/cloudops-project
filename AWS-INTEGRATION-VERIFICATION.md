# AWS Integration Verification

Date: 24 October 2026
Region: ap-southeast-2
Cluster: CloudOps-Cluster
Task definition: cloudops-task:4
Backend and ECS frontend image tags: 47bd7df

## Method

Standalone Fargate tasks used command overrides to run checks through
Flask's in-process test client, using the task's injected configuration
and IAM role. S3 and database calls were not mocked.

API tokens and database records were not printed.
No real API tokens were sent over public HTTP.
The ECS service remained at 0 desired tasks.

## RDS check

Task ID: 29fb01cd9ece4687a06bfeb03ba48495

The authenticated /users route returned HTTP 200 and a JSON list
after querying the real RDS database.

Observed log:
PASS: authenticated users route queried RDS successfully

Both containers stopped with exit code 0.
RDS stop was requested; the operator subsequently reported it stopped.

## S3 check

Task ID: 93fdac4b8c2743a284dedd79bd382f5d

The authenticated /upload route uploaded a generated 2x2 PNG.
The check downloaded the object and verified its bytes matched.
It then deleted the test object.

Observed logs:
PASS: authenticated upload and S3 read-back
PASS: test object deleted

Both containers stopped with exit code 0.

## Cleanup

The final ECS list-tasks query for desired status RUNNING returned:
{"taskArns": []}

## Limits

These checks exercised Flask routes directly inside the backend
container. They did not test Gunicorn, Nginx proxying, public HTTP,
TLS, load balancing, or sustained traffic.

## Live service check

A separate service test ran revision 4 with normal container startup
commands and one desired task.

Observed results:
- Browser GET / loaded the CloudOps Company Portal.
- GET /health returned HTTP 200 with {"status":"healthy"}.
- GET /api/users without a token returned HTTP 401 Unauthorized.

Requests reached Nginx through the task's public IP. The configured
backend startup command uses Gunicorn to serve Flask.

RDS remained stopped during this test. No real API tokens were sent
over public HTTP. TLS and load balancing were not tested.

## Live service cleanup

After the test, the service showed 0 desired, 0 running, and 0 pending.
The temporary HTTP rule for the tester's IPv4 /32 was removed.
Only the existing HTTP rule referencing the ALB security group remained.
