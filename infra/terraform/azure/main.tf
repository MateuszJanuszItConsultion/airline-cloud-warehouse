resource "azurerm_subnet" "main" {
  address_prefixes                              = ["172.16.0.0/24"]
  default_outbound_access_enabled               = true
  name                                          = "snet-polandcentral-1"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.main.name
  virtual_network_name                          = azurerm_virtual_network.main.name
}

resource "azurerm_resource_group" "main" {
  location   = "polandcentral"
  name       = "rg-airline-data-engineering"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_virtual_network" "main" {
  address_space                  = ["172.16.0.0/16"]
  location                       = azurerm_resource_group.main.location
  name                           = "vnet-polandcentral-1"
  private_endpoint_vnet_policies = "Disabled"
  resource_group_name            = azurerm_resource_group.main.name
    lifecycle {
        prevent_destroy = true
    }
}