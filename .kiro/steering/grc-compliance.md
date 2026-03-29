---
title: GRC Compliance Standards
inclusion: always
---

# GRC Compliance Standards

## Data Classification

All data MUST be classified according to sensitivity:

```python
from enum import Enum

class DataClassification(Enum):
    PUBLIC = "public"              # No restrictions
    INTERNAL = "internal"          # Internal use only
    CONFIDENTIAL = "confidential"  # Sensitive business data
    RESTRICTED = "restricted"      # PII, PHI, financial data
```

Document the classification of data handled by each Lambda function in its module docstring.

## PII Handling

### Never Log PII

```python
import structlog
log = structlog.get_logger()

# ❌ Bad
log.info("user_created", email=user["email"], ssn=user["ssn"])

# ✅ Good
log.info("user_created", user_id=user["id"])
```

### Never Store PII Without Encryption
- Use AWS KMS for encrypting RESTRICTED-class data at rest
- DynamoDB encryption at rest is enabled by default — do not disable it
- Never write PII to CloudWatch Logs

## Audit Logging

### Required Audit Events

Log all of the following to a dedicated audit DynamoDB table or CloudWatch log group:
- User authentication (success, failure, token expiry)
- Data access (read, download of restricted data)
- Data modification (create, update, delete)
- Permission changes
- Configuration changes

```python
import boto3
import os
from datetime import datetime, timezone

def log_audit_event(
    user_id: str,
    action: str,
    resource: str,
    resource_id: str,
    result: str,  # "success" | "failure"
    metadata: dict | None = None,
) -> None:
    table = boto3.resource("dynamodb").Table(os.environ["AUDIT_TABLE"])
    table.put_item(Item={
        "pk": f"AUDIT#{datetime.now(timezone.utc).strftime('%Y%m')}",
        "sk": f"{datetime.now(timezone.utc).isoformat()}#{resource_id}",
        "userId": user_id,
        "action": action,
        "resource": resource,
        "resourceId": resource_id,
        "result": result,
        "metadata": metadata or {},
    })
```

## Access Control (RBAC)

```python
from enum import Enum

class Role(Enum):
    USER = "user"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"

class Permission(Enum):
    READ_DATA = "read:data"
    WRITE_DATA = "write:data"
    DELETE_DATA = "delete:data"
    MANAGE_SETTINGS = "manage:settings"

ROLE_PERMISSIONS: dict[Role, list[Permission]] = {
    Role.USER: [Permission.READ_DATA],
    Role.ADMIN: [Permission.READ_DATA, Permission.WRITE_DATA],
    Role.SUPER_ADMIN: list(Permission),
}

def require_permission(role: str, permission: Permission) -> None:
    try:
        role_enum = Role(role)
    except ValueError:
        raise PermissionError(f"Unknown role: {role}")
    if permission not in ROLE_PERMISSIONS.get(role_enum, []):
        raise PermissionError(f"Role {role} lacks permission {permission.value}")
```

## Data Retention

Always set a `ttl` attribute on DynamoDB items at write time. Enable TTL on the table in CDK.

```python
from datetime import datetime, timezone, timedelta

RETENTION_DAYS = {
    "audit_logs": 2555,    # 7 years
    "user_sessions": 90,
    "temp_artifacts": 7,
    "analytics": 365,
}

def get_ttl(data_type: str) -> int:
    days = RETENTION_DAYS.get(data_type, 90)
    return int((datetime.now(timezone.utc) + timedelta(days=days)).timestamp())

# Usage at write time
table.put_item(Item={
    **your_item,
    "ttl": get_ttl("user_sessions"),
})
```

## Consent Management
- For any product collecting user consent: record consent type, granted flag, timestamp, IP, policy version
- Store in DynamoDB with RESTRICTED classification
- Audit log every consent change
- Never infer consent — explicit opt-in required

## Encryption

### Data at Rest — AWS KMS

```python
import boto3
import base64

kms = boto3.client("kms", region_name="us-east-1")

def encrypt_data(plaintext: str, key_id: str) -> str:
    resp = kms.encrypt(KeyId=key_id, Plaintext=plaintext.encode())
    return base64.b64encode(resp["CiphertextBlob"]).decode()

def decrypt_data(ciphertext: str) -> str:
    resp = kms.decrypt(CiphertextBlob=base64.b64decode(ciphertext))
    return resp["Plaintext"].decode()
```

### Data in Transit
- All API Gateway endpoints: HTTPS only (enforced by AWS — do not disable)
- Use VPC endpoints for S3/DynamoDB to avoid internet traversal where possible

## SOC 2 Alignment

### Change Management
- All infrastructure changes via CDK PRs — require review before merge
- All Lambda changes via CI/CD — never deploy manually to production
- Git history is the audit trail — commit messages must be descriptive

### Incident Response
- Define severity levels: low / medium / high / critical
- Critical incidents: page on-call immediately
- During active Kiro dev sessions: document blockers in `.kiro/state/blockers.md`

## Compliance Checklist

- [ ] All data classified by sensitivity level
- [ ] PII never logged in plaintext
- [ ] Audit logging for all sensitive actions
- [ ] RBAC implemented and enforced in Lambda authorizers
- [ ] DynamoDB TTL set on all tables at write time
- [ ] KMS encryption for RESTRICTED-class data
- [ ] pip-audit running in CI
- [ ] IAM least privilege for all Lambda roles
- [ ] No real secrets in environment variables for production
- [ ] Incident response plan documented

## Anti-Patterns

❌ Don't store PII in CloudWatch Logs
❌ Don't skip audit logging for "minor" actions
❌ Don't implement custom encryption — use AWS KMS
❌ Don't grant broad IAM policies (no `*` wildcards without justification)
❌ Don't retain data indefinitely — use DynamoDB TTL
❌ Don't assume consent — explicit opt-in required
