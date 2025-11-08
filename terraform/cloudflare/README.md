# Cloudflare Terraform Configuration

This workspace manages Cloudflare resources including the Kubernetes CRD schemas hosting.

## Prerequisites

- Terraform Cloud workspace: `cloudflare` in organization `sbbh-cloud`
- TFE variable: `TF_VAR_CLOUDFLARE_API_TOKEN` (set in workspace)
- Cloudflare account: `sbbh.cloud`

## Resources

### Cloudflare Pages - Kubernetes Schemas

- **Project**: `kubernetes-schemas`
- **URL**: `https://kubernetes-schemas.pages.dev`
- **Purpose**: Hosts JSON schemas extracted from cluster CRDs for IDE validation

## GitHub Actions Setup

After running Terraform, add these secrets to your GitHub repository:

1. **CLOUDFLARE_API_TOKEN**
   - Same token used in `TF_VAR_CLOUDFLARE_API_TOKEN`
   - Permissions needed: `Account:Cloudflare Pages:Edit`

2. **CLOUDFLARE_ACCOUNT_ID**
   - Get from Terraform output: `terraform output cloudflare_account_id`
   - Or from Bitwarden: `bwget cloudflare.com account-id`

### Setting GitHub Secrets

```bash
# Using GitHub CLI
gh secret set CLOUDFLARE_API_TOKEN -b "your-token-here"
gh secret set CLOUDFLARE_ACCOUNT_ID -b "$(terraform output -raw cloudflare_account_id)"
```

## Usage

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply
terraform apply

# Get outputs
terraform output kubernetes_schemas_url
terraform output cloudflare_account_id
```

## Workflow

The `.github/workflows/schemas.yaml` workflow will:
1. Run daily to extract CRDs from your cluster
2. Convert them to JSON schemas
3. Publish to the Cloudflare Pages site
4. Make schemas available at `https://kubernetes-schemas.pages.dev/`
