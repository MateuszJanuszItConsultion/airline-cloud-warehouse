variable "location" {
  description = "Azure region for sandbox resources"
  type        = string
  default     = "polandcentral"
}

variable "project" {
  description = "Project name used in tags"
  type        = string
  default     = "airline-cloud-warehouse"
}

variable "subnets" {
  type        = map(string)
  description = "Map of subnets in name => CIDR format"
  default = {
    snet-ingest  = "10.10.1.0/24"
    snet-compute = "10.10.2.0/24"
  }
  validation {
    condition = alltrue([
      for cidr in var.subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet values must be valid IPv4 CIDR blocks (e.g., '10.10.1.0/24')."
  }
}
