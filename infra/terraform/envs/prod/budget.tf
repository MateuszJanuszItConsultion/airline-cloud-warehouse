data "azurerm_subscription" "current" {}

module "budget" {
  source = "../../modules/budget"

  subscription_id = data.azurerm_subscription.current.id
  amount          = var.budget_amount
  contact_email   = var.budget_contact_email
}