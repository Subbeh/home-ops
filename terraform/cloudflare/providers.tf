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
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.10.0"
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

# provider "ovh" {
#   endpoint           = "ovh-ca"
#   application_key    = var.OVH_APPLICATION_KEY
#   application_secret = var.OVH_APPLICATION_SECRET
#   consumer_key       = var.OVH_CONSUMER_KEY
# }
