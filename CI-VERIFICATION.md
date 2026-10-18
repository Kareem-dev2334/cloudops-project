# CloudOps CI Verification

Verified: 18 October 2026

## Workflow scope

Workflow: `.github/workflows/ci.yml`

Runs on pushes to `main` and pull requests targeting `main`.

### Application checks

- Python 3.11 syntax check for `app.py`
- Backend security tests
- Backend and frontend Docker image builds

### Terraform checks

Directory: `terraform-vpc-lab/`
Terraform version: `1.16.5`

Commands:

- `terraform fmt -check -recursive`
- `terraform init -backend=false -input=false -lockfile=readonly`
- `terraform validate -no-color`

The provider lock file is committed.
These checks require no AWS credentials and do not deploy resources.
The separate `terraform/` directory is outside this job's scope.

## Required merge checks

The active Protect Main Branch ruleset requires:

- `backend-check`
- `Terraform checks`

Pull requests are required, force pushes are blocked, and the
ruleset bypass list is empty.

## Successful verification

[PR #3](https://github.com/Kareem-dev2334/cloudops-project/pull/3)
added Terraform CI checks.

- Implementation commit: `78f0ee1`
- Both CI jobs passed.
- Merged into `main` as `69154fa`.
- Local formatting and validation checks returned exit code 0.

## Deliberate failure test

[PR #4](https://github.com/Kareem-dev2334/cloudops-project/pull/4)
tested rejection of incorrect Terraform formatting.

- Test commit: `38f88dd`
- Added an intentionally unformatted `ci_gate_test.tf`.
- Local and CI formatting checks returned exit code 3.
- Terraform checks was marked Required and merging was disabled.
- The PR was closed without merging.
- The test branch was deleted locally and remotely.

## Limitations

Formatting and validation do not prove that AWS deployment will
succeed, that infrastructure is secure, or that services can connect.

No Terraform plan, apply, or destroy runs in this workflow.
