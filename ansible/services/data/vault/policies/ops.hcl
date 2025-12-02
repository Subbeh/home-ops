# Homelab operations - KV v2 secrets engine
path "ops/data/*" {
  capabilities = ["read", "create", "update"]
}

path "ops/metadata/*" {
  capabilities = ["read", "list", "create", "update"]
}
