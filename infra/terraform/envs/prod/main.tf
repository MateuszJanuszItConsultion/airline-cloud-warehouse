resource "azurerm_resource_group" "main" {
  location = "polandcentral"
  name     = "rg-airline-data-engineering"
  lifecycle {
    prevent_destroy = true
  }
}

module "network" {
  source = "../../modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}