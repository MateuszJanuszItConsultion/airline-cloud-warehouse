resource "azurerm_resource_group" "sandbox" {
  name     = "rg-tf-sandbox"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_virtual_network" "sandbox" {
  name                = "vnet-tf-sandbox"
  location            = azurerm_resource_group.sandbox.location
  resource_group_name = azurerm_resource_group.sandbox.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.common_tags
}

data "azurerm_resource_group" "airline" {
  name = "rg-airline-data-engineering"
}