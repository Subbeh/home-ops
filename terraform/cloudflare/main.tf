data "cloudflare_zone" "default" {
  filter = {
    account = {
      id = var.CLOUDFLARE_ACCOUNT_ID
    }
    name = var.cf_zone
  }
}

