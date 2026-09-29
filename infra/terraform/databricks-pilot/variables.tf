variable "databricks_profile" {
  description = "Databricks CLI profile used for authentication"
  type        = string
  default     = "DEFAULT"
}

variable "pilot_secret_value" {
  description = "Dummy secret value for pilot testing - never a real secret"
  type        = string
  sensitive   = true
}