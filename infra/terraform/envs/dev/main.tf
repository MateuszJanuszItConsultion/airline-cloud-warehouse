resource "azurerm_resource_group" "main" {
  location = "polandcentral"
  name     = "rg-airline-data-engineering-dev"
}

module "network" {
  source = "../../modules/network"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  vnet_name               = "vnet-airline-dev"
  vnet_address_space      = ["10.20.0.0/16"]
  subnet_name             = "snet-airline-dev"
  subnet_address_prefixes = ["10.20.1.0/24"]
}