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

A live service check of the updated Gunicorn/Nginx path remains pending.
