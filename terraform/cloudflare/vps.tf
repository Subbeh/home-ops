data "tfe_outputs" "hetzner" {
  organization = "sbbh-cloud"
  workspace    = "hetzner"
}

module "vps_dns" {
  source = "./modules/dns"

  zone_id      = data.cloudflare_zone.default.id
  subdomain    = "vps"
  ipv4_address = data.tfe_outputs.hetzner.values.vps_ipv4
  type         = "A"
  enable_proxy = false
}
