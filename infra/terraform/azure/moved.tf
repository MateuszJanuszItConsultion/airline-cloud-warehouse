moved {
  from = azurerm_consumption_budget_subscription.monthly
  to   = module.budget.azurerm_consumption_budget_subscription.monthly
}