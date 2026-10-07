variable "location" {
  description = "Azure region for Terraform state storage"
  type        = string
  default     = "polandcentral"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase letters and digits)"
  type        = string
  default     = "terraformstatestoragemj"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters, lowercase letters and digits only."
  }
}

variable "github_repository" {
  description = "GitHub repository in owner/name format"
  type        = string
  default     = "MateuszJanuszItConsultion/airline-cloud-warehouse"
}