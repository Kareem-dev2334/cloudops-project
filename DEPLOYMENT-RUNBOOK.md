# CloudOps Deployment Runbook

## Scope

Operate the existing ECS service in ap-southeast-2.
This runbook does not provision a new AWS environment.

Run local build commands in Ubuntu.
Run ECS inspection and service commands in AWS CloudShell.

## Deployment baseline

Last verified on 26 October 2026:

| Component | Value |
|---|---|
| Cluster | CloudOps-Cluster |
| Service | cloudops-service |
| Task definition | cloudops-task:6 |
| Frontend image tag | dd56280 |
| Backend image tag | 47bd7df |
| Previous verified task definition | cloudops-task:5 |

Revision 5 contains the previous frontend with the same backend image
and read-only backend configuration.

These are historical baseline values. Inspect current AWS state before
making changes. A task-definition revision being ACTIVE does not prove
that its application works.

## Before making changes

1. Confirm the intended Git commit is merged and required CI checks pass.
2. Confirm the AWS account and region.
3. Record the service's current task-definition revision and task counts.
4. Check that the intended and rollback images remain available in ECR.
5. Review the task-definition changes before registering a revision.
6. Agree on test duration and cleanup before starting chargeable resources.

Never print secrets or send real API tokens over public HTTP.

## Inspect current service

Run in AWS CloudShell:

```bash
aws sts get-caller-identity --no-cli-pager

aws ecs describe-services \
  --cluster CloudOps-Cluster \
  --services cloudops-service \
  --region ap-southeast-2 \
  --query 'services[0].{taskDefinition:taskDefinition,desired:desiredCount,running:runningCount,pending:pendingCount,deployments:deployments[].{status:status,rollout:rolloutState}}' \
  --output json \
  --no-cli-pager
```

These commands inspect state without starting tasks.

## Prepare a release

In Ubuntu:

1. Start from the intended merged commit with a clean working tree.
2. Run the relevant local checks and confirm required CI checks passed.
3. Build the changed image using the Git commit as its tag.
4. For the ECS frontend, build with NGINX_CONFIG=default.ecs.conf.
5. Validate Nginx configuration and confirm linux/amd64 compatibility.
6. Authenticate to the intended ECR account and push the image.
7. Record the pushed image URI and digest.

ECR tags are immutable. Use a new tag for changed image content.

In CloudShell:

1. Export the service's current task definition.
2. Remove response-only metadata before registration.
3. Change only the intended settings or image references.
4. Preserve IAM roles, injected configuration, networking, logging,
   resource limits, and backend read-only/tmpfs settings.
5. Review the JSON and register it.
6. Record the assigned revision; do not assume its number.

## Update service configuration while scaled to zero

This procedure is for the paused lab, not an active customer service.
Stop if desired, running, or pending counts are not all zero.

Record the current revision as the rollback candidate before changing it.
Confirm the candidate's task definition and images still exist.

Replace REVIEWED_REVISION below with the registered revision number.

```bash
aws ecs update-service \
  --cluster CloudOps-Cluster \
  --service cloudops-service \
  --task-definition cloudops-task:REVIEWED_REVISION \
  --desired-count 0 \
  --region ap-southeast-2 \
  --query 'service.{taskDefinition:taskDefinition,desired:desiredCount,running:runningCount,pending:pendingCount}' \
  --output json \
  --no-cli-pager
```

Repeat the service inspection command from the previous section.
Confirm the intended revision, a completed primary rollout, and zero
desired, running, and pending tasks.

A completed rollout at zero tasks verifies configuration only.

## Brief live verification

Starting tasks incurs Fargate, public IPv4, and logging charges.
Review costs and authorize the test before starting.

1. Obtain the tester's current public IPv4 address from their computer.
2. Add temporary TCP port 80 access to the ECS security group
   sg-093800cd96c077fcf, restricted to that IPv4 /32.
3. Record the returned SecurityGroupRuleId for cleanup.
4. Start one service task:

```bash
aws ecs update-service \
  --cluster CloudOps-Cluster \
  --service cloudops-service \
  --desired-count 1 \
  --region ap-southeast-2 \
  --query 'service.{taskDefinition:taskDefinition,desired:desiredCount,running:runningCount,pending:pendingCount}' \
  --output json \
  --no-cli-pager
```

5. Find the service task using ecs list-tasks.
6. Inspect it using ecs describe-tasks. Confirm the intended revision
   and both containers RUNNING.
7. Retrieve its public IP from its attached network interface.
   Do not reuse an IP from an earlier test.
8. From the tester's computer, open the portal and click Check backend.
9. Check /health and unauthenticated /api/users with curl.

Expected results:
- Portal renders the intended frontend.
- Health button reports Backend healthy.
- /health returns 200 with {"status":"healthy"}.
- /api/users without a token returns 401 with {"error":"Unauthorized"}.

These checks do not verify RDS or S3 connectivity.
Keep RDS stopped unless a separately authorized database test needs it.
Never send real API tokens over public HTTP.

## Troubleshooting

- No running task: inspect service events and stopped-task reasons.
- Container exits: inspect its exit code and CloudWatch logs.
- HTTP timeout: check task state, current public IP, tester IPv4 /32,
  security-group rules, and network routing.
- HTTP 502: inspect Nginx and backend logs and the upstream address.
- Health succeeds but a data operation fails: investigate that
  dependency's configuration, permissions, and connectivity separately.

Do not repeatedly launch tasks without inspecting why earlier ones failed.

## Rollback

The rollback target is the revision recorded before the release.
Do not automatically select revision 3 or assume the previous number
is the correct candidate.

For this paused lab:
1. Scale the service to zero and confirm all task counts reach zero.
2. Update the service to the reviewed rollback revision using the
   scaled-to-zero update procedure above.
3. Confirm the selected revision and rollout state.
4. If live recovery must be verified, authorize and perform a separate
   brief live test, then clean up.

Switching configuration at zero tasks does not prove live recovery,
zero downtime, recovery time, or automatic rollback.

## Cleanup after every live test

Run even if application checks fail:

```bash
aws ecs update-service \
  --cluster CloudOps-Cluster \
  --service cloudops-service \
  --desired-count 0 \
  --region ap-southeast-2 \
  --no-cli-pager
```

Revoke the temporary rule using the ID recorded for this test:

```bash
aws ec2 revoke-security-group-ingress \
  --group-id sg-093800cd96c077fcf \
  --security-group-rule-ids TEMPORARY_RULE_ID \
  --region ap-southeast-2 \
  --no-cli-pager
```

Then:
- Inspect the service until desired, running, and pending are all zero.
- Verify any standalone test tasks have stopped.
- If RDS was started, stop it and verify its final state.
- Verify deletion of any generated S3 test objects.
- Record the final service revision and cleanup results.

Do not delete the entire security group or remove unrelated rules.
Zero tasks and stopped RDS do not eliminate storage charges.

## Verification evidence

- [Portal verification](PORTAL-VERIFICATION.md)
- [Read-only backend verification](READONLY-BACKEND-VERIFICATION.md)
- [AWS integration verification](AWS-INTEGRATION-VERIFICATION.md)
- [Historical rollback exercise](ROLLBACK-VERIFICATION.md)

This runbook consolidates existing procedures. It has not yet been
executed end to end as a single exercise.
