output vm_id {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "The ID of the virtual machine."
}

output vm_public_ip {
  value       = azurerm_public_ip.vm.ip_address
  description = "The public IP address of the virtual machine."
  sensitive   = true
}