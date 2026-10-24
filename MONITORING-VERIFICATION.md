# CloudWatch Verification

Date: 24 October 2026
Region: ap-southeast-2

## Log retention

Log group: /ecs/cloudops-task

The initial query returned no retention policy.
A 30-day retention policy was applied and verified.

Log events older than the retention period become eligible for deletion.

## Temporary CPU alarm

Alarm name: cloudops-service-high-cpu
Namespace: AWS/ECS
Metric: CPUUtilization
Statistic: Average
ClusterName: CloudOps-Cluster
ServiceName: cloudops-service

Configuration verified:
- Threshold: greater than 80 percent.
- Period: 60 seconds.
- Evaluation periods: 2.
- Datapoints to alarm: 2.
- Missing data treatment: missing.
- Actions disabled; no notification or scaling actions configured.

The initial state was INSUFFICIENT_DATA.
The returned reason was "Unchecked: Initial alarm creation".

## Cleanup

The temporary alarm was deleted after inspection.
A describe-alarms query for its name returned an empty list.

The log group's 30-day retention policy remains configured.

## Limits

This exercise verified configuration and deletion.
It did not verify a real CPU threshold breach, notification delivery,
or application availability.

No ECS tasks or RDS instances were started for this exercise.
No CPU alarm remains deployed after cleanup.
