output "sandbox_rg_id" {
  value = azurerm_resource_group.sandbox.id
}

output "airline_rg_location" {
  value = data.azurerm_resource_group.airline.location
}

output "airline_rg_tags" {
  value = data.azurerm_resource_group.airline.tags
}