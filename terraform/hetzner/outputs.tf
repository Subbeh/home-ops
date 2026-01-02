output "vps_ipv4" {
  description = "VPS IPv4 address"
  value       = hcloud_primary_ip.default.ip_address
}
