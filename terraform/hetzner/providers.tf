terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.72.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.57.0"
    }
  }
  required_version = ">= 1.13.5"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "hetzner"
    }
  }
}
