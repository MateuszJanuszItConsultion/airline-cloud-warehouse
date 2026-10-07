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

variable "github_owner" {
  description = "GitHub account that owns the repository"
  type        = string
  default     = "MateuszJanuszItConsultion"
}

variable "github_owner_id" {
  description = "Immutable numeric ID of the GitHub owner (part of the OIDC subject)"
  type        = number
  default     = 315073691
}

variable "github_repository_name" {
  description = "GitHub repository name"
  type        = string
  default     = "airline-cloud-warehouse"
}

variable "github_repository_id" {
  description = "Immutable numeric ID of the GitHub repository (part of the OIDC subject)"
  type        = number
  default     = 1327683054
}