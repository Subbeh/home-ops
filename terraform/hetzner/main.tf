resource "hcloud_ssh_key" "default" {
  name       = "home-ops"
  public_key = file(pathexpand("~/.ssh/keys/home-ops.pub"))
}

resource "hcloud_ssh_key" "restic" {
  name       = "restic"
  public_key = file("${path.module}/../../.private/core/restic_ssh_key.pub")
}
