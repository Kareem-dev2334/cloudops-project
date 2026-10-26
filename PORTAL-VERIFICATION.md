# Portal Redesign Verification

Date: 26 October 2026
Region: ap-southeast-2
Task definition: cloudops-task:6
Frontend image tag: dd56280
Backend image tag: 47bd7df

## Local verification

The redesigned portal rendered in Ubuntu's browser.
The health button reported Backend healthy.
The operator confirmed cards stacked without horizontal scrolling
at a narrow browser width.

The ECS frontend image passed nginx -t and reported linux/amd64.
Its proxy configuration used 127.0.0.1:5000.

## Live service verification

Task: c799a80ccd9c4eb4a8b84bb3c2b914cf

Both containers reached RUNNING using normal startup commands.
The operator confirmed the redesigned portal and health button worked
through the task's public IP.

GET /health returned HTTP 200 with {"status":"healthy"}.
GET /api/users without authentication returned HTTP 401
with {"error":"Unauthorized"}.

No real API tokens were sent over public HTTP.

## Cleanup

The service was scaled to zero.
The operator subsequently reported all service task counts were zero.

Temporary HTTP rule sgr-081f6f49552f10e50 was revoked successfully.
The service remained configured for revision 6.

## Limits

The health endpoint does not query RDS or S3.
Authenticated API operations, TLS, load balancing, sustained traffic,
and the health button's failure state were not tested in this exercise.
