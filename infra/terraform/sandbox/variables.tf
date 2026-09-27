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