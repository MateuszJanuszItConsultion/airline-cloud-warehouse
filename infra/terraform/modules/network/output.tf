output "subnet_id" {
  value       = azurerm_subnet.main.id
  description = "The ID of the primary subnet used for network interfaces and virtual machine deployment."
}