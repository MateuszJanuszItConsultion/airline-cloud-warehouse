locals {
  notifications = [
    { threshold = 50, threshold_type = "Actual" },
    { threshold = 80, threshold_type = "Actual" },
    { threshold = 100, threshold_type = "Forecasted" },
  ]
}

data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-subscription-monthly"
  subscription_id = var.subscription_id
  amount          = var.amount
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z"
  }

  dynamic "notification" {
    for_each = local.notifications

    content {
      enabled        = true
      threshold      = notification.value.threshold
      operator       = "GreaterThan"
      threshold_type = notification.value.threshold_type
      contact_emails = [var.contact_email]
    }
  }
}