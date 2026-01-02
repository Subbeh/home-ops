tfe_workspaces = [
  {
    name              = "hetzner"
    working_directory = "terraform/hetzner"
    execution_mode    = "local"
  },
  {
    name              = "cloudflare"
    working_directory = "terraform/cloudflare"
    execution_mode    = "local"
  },
  {
    name              = "aws-organization"
    working_directory = "terraform/aws/organization"
    execution_mode    = "local"
  },
  {
    name              = "aws-security-account"
    working_directory = "terraform/aws/security-account"
  },
  {
    name              = "aws-sandbox-account"
    working_directory = "terraform/aws/sandbox-account"
  },
  {
    name              = "aws-prod-account"
    working_directory = "terraform/aws/prod-account"
  }
]
