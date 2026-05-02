---
title: Peregrine Publish Pipeline
inclusion: always
---

# Peregrine Publish Pipeline

This project includes a CI/CD pipeline that packages build artifacts and ships them to Peregrine for hosting and deployment.

## peregrine.json — Fill It In

The file `peregrine.json` at the project root controls what gets packaged and where it goes. **When you have enough context to fill it in, do so immediately.** Do not leave `CHANGE_ME` placeholders.

### When to write peregrine.json

Fill in `peregrine.json` as soon as you know:
- The product name / identifier (e.g. `alpha-danelle`, `aeos-pc3`, `gdna-smb`)
- What type of project this is (`landing-page`, `demo`, `onboarding`, or `saas-app`)
- The URL slug for hosting (e.g. `alpha`, `migrate`, `smb-onboard`)

### How to fill it in

```json
{
  "productId": "alpha-danelle",
  "projectType": "demo",
  "slug": "alpha",
  "domain": "demos.gdna.io",
  "artifactPath": "demo"
}
```

### Field reference

| Field | What it is | Examples |
|-------|-----------|----------|
| `productId` | Unique product identifier in Peregrine. Lowercase, hyphenated. | `alpha-danelle`, `aeos-pc3`, `gdna-smb-landing` |
| `projectType` | What kind of deliverable. Determines zip name and deploy handler. | `landing-page`, `demo`, `onboarding`, `saas-app` |
| `slug` | URL slug. Becomes the subdomain: `{slug}.{domain}`. | `alpha`, `migrate`, `smb-onboard` |
| `domain` | Base domain for hosting. | `gdna.io`, `aeospc3.com`, `demos.gdna.io` |
| `artifactPath` | Directory containing the build output to zip and deploy. | `landing`, `demo`, `onboarding`, `dist` |

### Project type → artifact path conventions

| projectType | Default artifactPath | Zip produced | Peregrine deploys to |
|-------------|---------------------|-------------|---------------------|
| `landing-page` | `landing/` | `landing-dist.zip` | `{slug}.{domain}` via landing-page-handler |
| `demo` | `demo/` | `demo-bundle.zip` | `{slug}.demos.gdna.io` via demo-catalog |
| `onboarding` | `onboarding/` | `onboarding-dist.zip` | `{slug}.onboard.gdna.io` |
| `saas-app` | `dist/` | `frontend-dist.zip` | Customer account via product-update |

### Domain conventions

| Project type | Domain pattern | Example |
|-------------|---------------|--------|
| Landing pages | `{slug}.aeospc3.com` or `{slug}.gdna.io` | `migrate.aeospc3.com` |
| Demos | `{slug}.demos.gdna.io` | `alpha.demos.gdna.io` |
| Onboarding | `{slug}.onboard.gdna.io` | `acme.onboard.gdna.io` |
| SaaS apps | `{slug}.aeospc3.com` or custom | `app.aeospc3.com` |

## How the pipeline works

1. You build the asset (HTML, JSX, React app, etc.) in the `artifactPath` directory
2. You tag: `git tag v0.1.0 && git push --tags`
3. GH Actions reads `peregrine.json`, zips the artifact path, uploads to S3
4. Peregrine registers the version, promotes it to current
5. Landing pages auto-deploy immediately. Other types stage for manual or agentic deploy.

## Manual publish (no tag needed)

```bash
.kiro/scripts/package-release.sh 0.1.0
```

Same logic as the GH Actions workflow but runs locally. Requires AWS credentials.

## Rules for the agent

- **Write peregrine.json early.** As soon as you know the product name and project type, replace the CHANGE_ME values. Don't wait until the build is done.
- **Match artifactPath to where you put the build output.** If you're building a landing page in `landing/`, set `artifactPath` to `landing`.
- **Use lowercase hyphenated values** for productId and slug. No spaces, no underscores.
- **Don't invent new projectTypes.** Use one of: `landing-page`, `demo`, `onboarding`, `saas-app`.
- **The slug becomes a subdomain.** Keep it short, memorable, and URL-safe.
