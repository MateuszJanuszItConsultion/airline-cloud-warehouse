output "principal_id" {
  value       = azurerm_automation_account.main.identity[0].principal_id
  description = "The principal ID of the system-assigned managed identity."
}