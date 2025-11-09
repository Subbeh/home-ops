terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.70.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
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

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}
