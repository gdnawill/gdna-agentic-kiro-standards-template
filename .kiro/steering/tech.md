---
title: Technology Stack
inclusion: always
---

# Technology Stack (Agentic)

## Infrastructure
- **AWS** — primary cloud
- **Lambda** — compute (event-driven, serverless)
- **DynamoDB** — state, session storage, conversation history
- **S3** — document storage, build artifacts, spec files
- **API Gateway** or **Lambda Function URL** — HTTP entry points
- **AWS CDK** (Python) — IaC; see `gdna-iac-standards.md`

## Backend
- **Python 3.12** — sole language for this project type
- **Strands Agents** — agent framework (loop, tool use, memory)
- **Amazon Bedrock** — LLM (Claude 3.5 Sonnet / Claude 3 Haiku)
- **MCP** — tool protocol; see `agentic-ai-standards.md`
- **Pydantic** — data validation and schema enforcement
- **boto3** — AWS SDK

## Key Libraries

| Library | Purpose |
|---------|---------|
| `strands-agents` | Agent loop, Bedrock integration, tool orchestration |
| `mcp` | MCP server/client protocol |
| `pydantic` | Schema validation, data models |
| `boto3` | AWS service clients |
| `aws-cdk-lib` | Infrastructure as code |
| `structlog` | Structured JSON logging |
| `pytest` | Testing framework |
| `moto` | AWS service mocking for tests |
| `pip-audit` | Dependency vulnerability scanning |

## Common Commands

```bash
# Install dependencies
pip install -r requirements.txt -r requirements-dev.txt

# Run tests (unit only — fast)
pytest tests/unit/ -q --tb=short -x

# Run all tests with coverage
pytest -q --tb=short -x --cov=src --cov-report=term-missing

# Deploy infrastructure
cdk deploy --all

# Synthesize CDK (dry run)
cdk synth

# Diff against deployed stack
cdk diff
```

## Environment Variables

Required in `.env` (never commit real values — use `.env.example`):
- `AWS_REGION` — target AWS region (e.g. `us-east-1`)
- `BEDROCK_MODEL_ID` — e.g. `anthropic.claude-3-5-sonnet-20241022-v2:0`
- `[PROJECT_TABLE_NAME]` — primary DynamoDB table
- `[PROJECT_BUCKET_NAME]` — primary S3 bucket

## AWS Configuration

- Region: `[region]` — fill in at project kickoff
- Account: `[account-id]` — fill in at project kickoff
- Deployed via CDK — see `infra/` directory
- All resources tagged: `Project`, `Environment`, `ManagedBy: cdk`

## Data Storage

- **DynamoDB**: session state, agent memory, conversation history, audit logs
- **S3**: documents, build artifacts, Kiro spec files (if remote)
- No RDS or relational databases in the agentic project type
