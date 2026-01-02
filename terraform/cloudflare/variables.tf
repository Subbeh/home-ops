variable "cf_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

variable "cf_zone" {
  description = "The Cloudflare zone"
  type        = string
}

