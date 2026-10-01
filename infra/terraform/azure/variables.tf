variable "budget_amount" {
  description = "Monthly subscription budget in the billing currency"
  type        = number
  sensitive   = true
  default     = 20
}

variable "budget_contact_email" {
  description = "E-mail address for budget alerts"
  type        = string
  sensitive   = true
}

variable "ssh_allowed_source_ip" {
  description = "IP address allowed to connect via SSH"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  sensitive   = true
}