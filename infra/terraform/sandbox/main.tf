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

resource "azurerm_subnet" "sandbox" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.sandbox.name
  virtual_network_name = azurerm_virtual_network.sandbox.name
  address_prefixes     = [each.value]
}

data "azurerm_resource_group" "airline" {
  name = "rg-airline-data-engineering"
}