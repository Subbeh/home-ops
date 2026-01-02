terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.72.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5"
    }
  }
  required_version = ">= 1.13.5"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "cloudflare"
    }
  }
}

data "cloudflare_zone" "default" {
  filter = {
    account = {
      id = var.cf_account_id
    }
    name = var.cf_zone
  }
}
