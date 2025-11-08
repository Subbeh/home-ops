resource "cloudflare_pages_project" "kubernetes_schemas" {
  account_id        = var.CLOUDFLARE_ACCOUNT_ID
  name              = var.schemas_subdomain
  production_branch = "main"
}

output "kubernetes_schemas_url" {
  description = "URL for the Kubernetes schemas site"
  value       = "https://${cloudflare_pages_project.kubernetes_schemas.subdomain}"
}
