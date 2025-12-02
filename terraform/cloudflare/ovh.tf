data "ovh_vps" "vps" {
  service_name = var.ovh_service_name
}

locals {
  ipv4 = [for ip in data.ovh_vps.vps.ips : ip if can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", ip))][0]
}

output "ipv4" {
  value = local.ipv4
}


module "cloudflare_dns" {
  source = "modules/dns"

  domain_name  = var.domain_name
  subdomain    = var.subdomain
  ipv4_address = module.ovh_vps.ipv4
  enable_proxy = false
}
