locals {
  # Compute hash of template file to trigger updates when it changes
  maintenance_template_hash = filemd5("./data/maintenance.js")
}

resource "cloudflare_workers_script" "maintenance" {
  account_id  = var.CLOUDFLARE_ACCOUNT_ID
  script_name = format("maintenance-%s", replace(var.cf_zone, ".", "-"))
  content = templatefile("./data/maintenance.js", {
    header        = "Home Operations"
    logo_url      = "https://i.imgur.com/qJ5M7Mu.png"
    image_url     = "https://c.tenor.com/MYZgsN2TDJAAAAAC/tenor.gif"
    favicon_url   = "https://cdn1.iconfinder.com/data/icons/ios-11-glyphs/30/maintenance-512.png"
    font          = "Poppins"
    email         = "support@sbbh.cloud"
    name          = "Sbbh"
    template_hash = local.maintenance_template_hash
    info_html     = <<-EOT
      <h1>This is why we can't have nice things</h1>
      <p>Home operations are down for maintenance. Normal service will resume once I stop "just changing one thing".</p>
    EOT
  })
}

resource "cloudflare_workers_route" "maintenance" {
  zone_id = data.cloudflare_zone.default.zone_id
  pattern = "maintenance.sbbh.cloud/*"
  script  = cloudflare_workers_script.maintenance.script_name
}

output "maintenance_route_id" {
  description = "The maintenance route ID"
  value       = cloudflare_workers_route.maintenance.id
}
