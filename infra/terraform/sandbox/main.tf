resource "azurerm_resource_group" "sandbox" {
  name     = "rg-tf-sandbox"
  location = "polandcentral"

  tags = {
    project    = "airline-cloud-warehouse"
    purpose    = "terraform-learning-s01"
    managed_by = "terraform"
  }
}