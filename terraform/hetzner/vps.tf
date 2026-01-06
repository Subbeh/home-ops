resource "hcloud_firewall" "default" {
  name = "vps-firewall"

  rule {
    description = "Allow ICMP traffic"
    direction   = "in"
    protocol    = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "Allow SSH traffic"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_primary_ip" "default" {
  name          = "primary-ip-vps"
  type          = "ipv4"
  assignee_type = "server"
  datacenter    = var.datacenter
  auto_delete   = false
}

resource "hcloud_server" "default" {
  name        = "vps"
  image       = var.vps_os_type
  server_type = var.vps_server_type
  datacenter  = var.datacenter

  firewall_ids = [hcloud_firewall.default.id]
  ssh_keys     = [hcloud_ssh_key.default.id]

  public_net {
    ipv4         = hcloud_primary_ip.default.id
    ipv4_enabled = true
    ipv6_enabled = false
  }

  lifecycle {
    ignore_changes = [
      ssh_keys
    ]
  }
}
