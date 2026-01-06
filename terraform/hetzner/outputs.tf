output "vps_ipv4" {
  description = "VPS IPv4 address"
  value       = hcloud_primary_ip.default.ip_address
}

output "storage_box_id" {
  description = "Storage Box ID"
  value       = hcloud_storage_box.default.id
}

output "storage_box_server" {
  description = "Storage Box server"
  value       = hcloud_storage_box.default.server
}

output "storage_box_username" {
  description = "Storage Box username"
  value       = hcloud_storage_box.default.username
}
