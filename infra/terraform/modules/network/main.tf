resource "azurerm_subnet" "main" {
  address_prefixes                              = var.subnet_address_prefixes
  default_outbound_access_enabled               = true
  name                                          = var.subnet_name
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.main.name
}

resource "azurerm_virtual_network" "main" {
  address_space                  = var.vnet_address_space
  location                       = var.location
  name                           = var.vnet_name
  private_endpoint_vnet_policies = "Disabled"
  resource_group_name            = var.resource_group_name
  lifecycle {
    prevent_destroy = true
  }
}