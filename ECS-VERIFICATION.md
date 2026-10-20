# ECS Deployment Verification

Date: 20 October 2026
Region: ap-southeast-2
Cluster: CloudOps-Cluster
Service: cloudops-service
Task definition: cloudops-task:3

## Deployment

Both containers used ECR images tagged 425c751:
- cloudops-backend:425c751
- cloudops-web:425c751

One Fargate task reached RUNNING, and deployment status showed Success.
The test used the task's public IP without a load balancer.
Temporary HTTP access was restricted to the tester's public IPv4 /32.

## Verified results

| Check | Observed result |
| --- | --- |
| Browser GET / | CloudOps Company Portal loaded |
| GET /health | HTTP 200 with {"status":"healthy"} |
| GET /api/users without a token | HTTP 401 with {"error":"Unauthorized"} |

These results verify frontend delivery, Nginx-to-Flask routing,
and rejection of unauthenticated requests.

## Limits

- /health does not connect to or query RDS.
- The unauthenticated /api/users request is rejected before database access.
- RDS queries and S3 uploads were not tested.
- No real authentication tokens were transmitted over HTTP.
- Portal status labels are static text, not live monitoring.

## Cleanup

The operator reported:
- Service desired count returned to 0, with 0 running and 0 pending.
- The temporary HTTP rule for the tester's IPv4 /32 was removed.
