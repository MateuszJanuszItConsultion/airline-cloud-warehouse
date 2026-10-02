moved {
  from = azurerm_public_ip.vm
  to   = module.airflow_vm.azurerm_public_ip.vm
}

moved {
  from = azurerm_network_security_group.vm
  to   = module.airflow_vm.azurerm_network_security_group.vm
}

moved {
  from = azurerm_network_interface.vm
  to   = module.airflow_vm.azurerm_network_interface.vm
}

moved {
  from = azurerm_network_interface_security_group_association.vm
  to   = module.airflow_vm.azurerm_network_interface_security_group_association.vm
}

moved {
  from = azurerm_linux_virtual_machine.vm
  to   = module.airflow_vm.azurerm_linux_virtual_machine.vm
}

