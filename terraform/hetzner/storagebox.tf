resource "hcloud_storage_box" "default" {
  name             = "storage-box"
  storage_box_type = var.storage_box_type
  location         = "fsn1"
  password         = var.storage_box_password

  access_settings = {
    reachable_externally = true
    ssh_enabled          = true
    zfs_enabled          = true
    samba_enabled        = false
    webdav_enabled       = false
  }

  ssh_keys = [
    hcloud_ssh_key.default.public_key,
    hcloud_ssh_key.restic.public_key,
  ]

  snapshot_plan = {
    max_snapshots = 10
    minute        = 30
    hour          = 1
    day_of_week   = 1
  }

  delete_protection = false
}
