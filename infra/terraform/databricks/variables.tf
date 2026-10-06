variable "databricks_profile" {
  description = "Databricks CLI profile for local runs. Leave null in CI to use environment variables."
  type        = string
  default     = null
}