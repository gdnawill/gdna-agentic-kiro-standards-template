---
title: gdna-iac-standards
inclusion: always
---

# g/d/n/a Infrastructure as Code Standards

## IaC Tool Choice — AWS CDK (TypeScript) Default

Use CDK when:
- AWS-only deployment
- Agentic architecture generation is part of the workflow
- Team is TypeScript or Python primary

Use Terraform when:
- Customer has existing Terraform estate
- Multi-cloud deployment required
- Customer mandate for HCL

## Project Structure (CDK)

```
packages/infra/
├── bin/app.ts
├── lib/
│   ├── stacks/
│   │   ├── agent-stack.ts
│   │   ├── data-stack.ts
│   │   └── monitoring-stack.ts
│   ├── constructs/
│   │   ├── bedrock-agent.ts
│   │   ├── compliant-bucket.ts
│   │   └── audited-lambda.ts
│   └── config/
│       ├── environments.ts
│       └── tags.ts
└── test/
```

## Mandatory Tagging

Seven tags. Required on every stack.

| Tag | What it answers | Examples |
|-----|----------------|----------|
| `gdna:deployed-by` | Who built this? | Always `gdna` |
| `gdna:customer` | End customer? | `rekalibrate`, `internal` |
| `gdna:engagement` | Which engagement? | `MAP-abc123` |
| `gdna:workload` | What system? | `agent-fleet`, `rag-pipeline` |
| `gdna:module` | Which piece? | `bedrock-agent`, `knowledge-base` |
| `gdna:env` | Where running? | `prod`, `dev`, `staging` |
| `gdna:grc` | Compliance scope? | `ftr`, `soc2`, `none` |

All values lowercase, hyphenated. Tag at App/Stack level — everything inherits.

## Security Defaults (Non-Negotiable)
- **S3:** Block all public access, enforce SSL, enable versioning
- **Lambda:** VPC-attached when accessing data stores, least-privilege IAM
- **Secrets:** AWS Secrets Manager — never SSM Parameter Store for secrets
- **KMS:** Customer-managed keys for CONFIDENTIAL data
- **CloudTrail:** Enabled with log file validation, multi-region
- **VPC:** No default VPC usage, private subnets for compute

## IAM — Least Privilege Always

```typescript
// ✅ Good — scoped permissions
lambdaFunction.addToRolePolicy(new iam.PolicyStatement({
  actions: ['bedrock:InvokeAgent'],
  resources: [agent.agentArn],
}));

// ❌ Bad
lambdaFunction.addToRolePolicy(new iam.PolicyStatement({
  actions: ['bedrock:*'],
  resources: ['*'],
}));
```

## CDK Testing
- Snapshot tests for every stack
- Fine-grained assertions for security-critical resources
- Run: `pnpm turbo test --filter=infra`

## Deployment Pipeline
- CDK Pipelines for self-mutating deployment
- Environment promotion: dev → staging → prod
- Manual approval gate before production
- Rollback capability for all stacks
