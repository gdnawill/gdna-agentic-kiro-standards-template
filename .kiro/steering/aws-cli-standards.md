---
title: AWS CLI Best Practices
inclusion: fileMatch
fileMatchPattern: "*.sh,*.bash,*aws*,*cli*"
---

# g/d/n/a AWS CLI Standards

## Session Configuration
```bash
export AWS_PAGER=""
```

## Authentication
- **Never use long-term credentials** in development or CI
- Use AWS SSO (`aws sso login`) for developer access
- Use OIDC (GitHub Actions → IAM role) for CI/CD
- Use IAM roles for Lambda/ECS — never embedded credentials

## CLI Output Handling
```bash
# ✅ Good — filtered query, no pager
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' \
  --output table \
  --no-cli-pager
```

## Profile Management
```bash
# ~/.aws/config
[profile gdna-dev]
sso_start_url = https://gdna.awsapps.com/start
sso_region = us-east-1
sso_account_id = 123456789012
sso_role_name = DeveloperAccess
region = us-east-1
output = json
```

## Scripting Safety
- `set -euo pipefail` in all bash scripts
- Use `--dry-run` for destructive operations when available
- Use `aws sts get-caller-identity` to verify credentials before operations
