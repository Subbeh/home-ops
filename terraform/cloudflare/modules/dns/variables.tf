variable "zone_id" {
  description = "The Cloudflare zone ID"
  type        = string
}

variable "subdomain" {
  description = "The subdomain to create"
  type        = string
}

variable "ipv4_address" {
  description = "The IPv4 address for the A record"
  type        = string
}

variable "type" {
  description = "The DNS record type (e.g., A, CNAME, etc.)"
  type        = string
}

variable "enable_proxy" {
  description = "Whether to enable Cloudflare proxy (orange cloud)"
  type        = bool
  default     = false
}
