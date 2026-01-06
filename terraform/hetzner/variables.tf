variable "location" {
  description = "Hetzner Cloud location name"
  type        = string
  default     = "nbg1"
}

variable "datacenter" {
  description = "Datacenter ID"
  type        = string
  default     = "nbg1-dc3"
}

variable "vps_server_type" {
  description = "Type of server, i.e how much CPU/RAM/Disk it uses"
  type        = string
  default     = "cx23"
}

variable "vps_os_type" {
  description = "Virtual Machine operating system"
  type        = string
  default     = "ubuntu-24.04"
}

variable "storage_box_password" {
  description = "Storage Box password"
  type        = string
  sensitive   = true
}

variable "storage_box_type" {
  description = "Type of Storage Box"
  type        = string
  default     = "bx11"
}
