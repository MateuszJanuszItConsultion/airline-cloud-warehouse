resource "azurerm_resource_group" "main" {
  location = "polandcentral"
  name     = "rg-airline-data-engineering"
  lifecycle {
    prevent_destroy = true
  }
}

module "network" {
  source = "../../modules/network"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  vnet_address_space      = ["172.16.0.0/16"]
  subnet_address_prefixes = ["172.16.0.0/24"]
  vnet_name               = "vnet-polandcentral-1"
  subnet_name             = "snet-polandcentral-1"
}