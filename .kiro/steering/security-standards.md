---
title: Security Standards
inclusion: always
---

# Security Standards (Agentic)

## Secret Management

### AWS Secrets Manager (Primary)

```python
import boto3
from functools import lru_cache

@lru_cache(maxsize=None)
def get_secret(secret_name: str, region: str = "us-east-1") -> str:
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return response["SecretString"]
```

### Never Hardcode Secrets

```python
# ❌ Bad
api_key = "sk_live_abc123xyz"

# ✅ Good — environment variable (local dev)
import os
api_key = os.environ["API_KEY"]

# ✅ Good — Secrets Manager (production)
api_key = get_secret("prod/api-key")
```

### Environment Variable Rules
- `.env` files: local dev only, never committed to git
- Use `.env.example` with placeholder values as the committed reference
- All Lambda functions source secrets from Secrets Manager or SSM Parameter Store at runtime
- SSM Parameter Store for non-sensitive config; Secrets Manager for credentials and keys

## Input Validation

### Pydantic at All Boundaries

```python
from pydantic import BaseModel, EmailStr, Field
from pydantic import ValidationError

class CreateUserRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    email: EmailStr
    role: str = Field(pattern="^(user|admin)$")

def handler(event: dict, context) -> dict:
    try:
        req = CreateUserRequest.model_validate(event.get("body", {}))
    except ValidationError as e:
        return {"statusCode": 400, "body": str(e)}
    # Safe to use req.name, req.email, etc.
```

### DynamoDB Injection Prevention
- Always use parameterized condition expressions — never string-format user input into queries
- Use `boto3` Key/Attr condition expressions

```python
# ❌ Bad — string interpolation in query
table.scan(FilterExpression=f"userId = {user_id}")

# ✅ Good — parameterized
from boto3.dynamodb.conditions import Key, Attr
table.query(KeyConditionExpression=Key("pk").eq(user_id))
```

## API Authentication

### Lambda Authorizers
- All API Gateway endpoints MUST use a Lambda authorizer or Cognito authorizer
- No unauthenticated endpoints unless explicitly documented with justification
- JWT tokens: verify signature, expiry, and issuer on every request

```python
import jwt

def authorizer_handler(event: dict, context) -> dict:
    token = event["authorizationToken"].replace("Bearer ", "")
    try:
        payload = jwt.decode(token, PUBLIC_KEY, algorithms=["RS256"])
        return generate_policy(payload["sub"], "Allow", event["methodArn"])
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        raise Exception("Unauthorized")
```

### API Key Management
- Generate with `secrets.token_hex(32)` (Python stdlib)
- Store only SHA-256 hash of the key in DynamoDB
- Return raw key to user exactly once at creation

```python
import secrets
import hashlib

def generate_api_key() -> tuple[str, str]:
    raw = f"sk_{secrets.token_hex(32)}"
    hashed = hashlib.sha256(raw.encode()).hexdigest()
    return raw, hashed  # store hashed, return raw once
```

## Rate Limiting
- Use API Gateway usage plans for external-facing APIs
- Use Lambda reserved concurrency to cap throughput per function
- For per-user rate limiting: DynamoDB atomic counter with TTL

## Logging and Monitoring

```python
import structlog

log = structlog.get_logger()

# ✅ Good — structured, no secrets
log.info("user.login", user_id=user_id, ip=ip_address)

# ❌ Bad — logging sensitive data
log.info("user.created", password=raw_password, api_key=key)
```

- Use `structlog` for structured JSON logging
- Redact: `password`, `api_key`, `token`, `secret`, `ssn`, `email` from all log output
- All Lambda logs go to CloudWatch — configure log group retention (90 days default)
- Attach a correlation ID to every request; propagate it through all downstream calls

## Dependency Scanning

```bash
# Install pip-audit
pip install pip-audit

# Scan for known vulnerabilities
pip-audit -r requirements.txt

# In CI (fail build on findings)
pip-audit --requirement requirements.txt --format=json
```

- Run `pip-audit` in CI on every PR
- Pin all dependency versions in `requirements.txt`
- Review and update dependencies monthly

## IAM Least Privilege
- Every Lambda function gets its own IAM role
- No `*` Actions or Resources unless absolutely required and documented with justification
- Roles defined in CDK — see `gdna-iac-standards.md`
- Never attach `AdministratorAccess` to any Lambda execution role

## Anti-Patterns

❌ Don't store secrets in Lambda environment variables for production — use Secrets Manager
❌ Don't expose raw error messages or stack traces to API callers (log internally, return generic 500)
❌ Don't use broad IAM policies — always least privilege
❌ Don't trust user input — validate with Pydantic at every Lambda entry point
❌ Don't commit `.env` files or any file containing real credentials
❌ Don't use MD5 or SHA1 for security purposes — use SHA-256 minimum
❌ Don't log PII or secrets — redact before logging
