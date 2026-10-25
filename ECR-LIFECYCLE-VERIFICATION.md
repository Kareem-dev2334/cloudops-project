# ECR Lifecycle Verification

Date: 25 October 2026
Region: ap-southeast-2

## Repositories

- cloudops-backend
- cloudops-web

Both repositories reported IMMUTABLE tag settings.
Neither initially had a lifecycle policy.

## Applied policy

Policy source: policies/ecr-untagged-policy.json

The policy expires untagged images pushed more than 14 days ago.
The age is measured from image push time, not when a tag is removed.
Tagged images are outside this rule's selection.

## Preview results

Before applying the policy, previews for both repositories completed:
- Status: COMPLETE
- expiringImageTotalCount: 0
- results: []

All images in the inspected inventory had tags.
The put-lifecycle-policy responses confirmed the reviewed policy was
applied to both repositories.

## Deployment images

Revision 3 references tag 425c751 for backend and frontend.
Revision 4 references tag 47bd7df for backend and frontend.

Both tags were present in ECR.
The frontend tags referenced the same image digest.

## Limits

Immutable tags prevent overwriting existing tags, but do not prevent
image deletion.

This rule does not clean up old tagged images.
The preview verified selection against the current inventory; no
automatic expiration was observed or tested.
