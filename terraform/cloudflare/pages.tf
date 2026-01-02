variable "schemas_subdomain" {
  description = "The subdomain for the Kubernetes schemas site"
  type        = string
}

resource "cloudflare_pages_project" "kubernetes_schemas" {
  account_id        = var.cf_account_id
  name              = var.schemas_subdomain
  production_branch = "main"
}

output "kubernetes_schemas_url" {
  description = "URL for the Kubernetes schemas site"
  value       = "https://${cloudflare_pages_project.kubernetes_schemas.subdomain}"
}
