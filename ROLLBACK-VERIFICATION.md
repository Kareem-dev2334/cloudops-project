# ECS Configuration Rollback Verification

Date: 25 October 2026
Region: ap-southeast-2
Cluster: CloudOps-Cluster
Service: cloudops-service

## Rollback candidate

Task definition cloudops-task:3 was ACTIVE and referenced:
- cloudops-backend:425c751
- cloudops-web:425c751

Both images were confirmed present in ECR.

Backend digest:
sha256:955fe5ea1f144e63676d4a9d590ff1733f882a31ee32f57c4c837c5e24abc29e

Frontend digest:
sha256:53b8e4592f1ecbee19491542d7fe910147908ba558bd3c4936ef324e2e2a38ec

The frontend tags 425c751 and 47bd7df referenced the same digest.

## Exercise

Initial state:
- Service referenced cloudops-task:4.
- Desired, running, and pending task counts were 0.
- Primary deployment rollout was COMPLETED.

The service was updated to cloudops-task:3 with desired count 0.
A subsequent query confirmed revision 3's primary rollout COMPLETED.

The service was then restored to cloudops-task:4 with desired count 0.
Desired, running, and pending counts were 0.
A subsequent query confirmed revision 4's primary rollout COMPLETED.

## Limits

This verified a configuration switch from revision 4 to 3 and back to 4
while scaled to zero. No tasks were started.

It did not verify revision 3 startup, live traffic recovery, recovery
time, zero downtime, or automatic rollback.

Task definition availability and image presence alone do not guarantee
a successful live recovery.
