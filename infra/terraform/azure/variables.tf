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