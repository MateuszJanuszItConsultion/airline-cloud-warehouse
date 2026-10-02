moved {
  from = azurerm_subnet.main
  to   = module.network.azurerm_subnet.main
}

moved {
  from = azurerm_virtual_network.main
  to   = module.network.azurerm_virtual_network.main
}