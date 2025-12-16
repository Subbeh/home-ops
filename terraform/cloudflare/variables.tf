# Cloudflare Variables
variable "CLOUDFLARE_API_TOKEN" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "CLOUDFLARE_ACCOUNT_ID" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "cf_zone" {
  description = "The Cloudflare zone"
  type        = string
}

# Cloudflare Pages Variables
variable "schemas_subdomain" {
  description = "The subdomain for the Kubernetes schemas site"
  type        = string
}

variable "maintenance_enabled" {
  description = "Flag to create/delete the worker route."
  type        = bool
  default     = false
}

# OVH Variables
# variable "OVH_APPLICATION_KEY" {
#   description = "OVH API Application Key"
#   type        = string
#   sensitive   = true
# }
#
# variable "OVH_APPLICATION_SECRET" {
#   description = "OVH API Application Secret"
#   type        = string
#   sensitive   = true
# }
#
# variable "OVH_CONSUMER_KEY" {
#   description = "OVH API Consumer Key"
#   type        = string
#   sensitive   = true
# }
#
# variable "ovh_service_name" {
#   description = "OVH VPS service name"
#   type        = string
# }
