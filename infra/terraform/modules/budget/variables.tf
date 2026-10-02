variable "subscription_id" {
  description = "Full subscription resource ID (/subscriptions/<guid>)"
  type        = string
}

variable "amount" {
  description = "Monthly budget amount in the billing currency"
  type        = number
}

variable "contact_email" {
  description = "E-mail address for budget alerts"
  type        = string
  sensitive   = true
}