resource "azurerm_resource_group" "sandbox" {
  name     = "rg-tf-sandbox"
  location = var.location
  tags     = local.common_tags
}

data "azurerm_resource_group" "airline" {
  name = "rg-airline-data-engineering"
}