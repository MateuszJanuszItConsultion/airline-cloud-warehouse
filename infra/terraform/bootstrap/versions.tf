terraform {
  required_version = "~> 1.16"

  backend "azurerm" {
    storage_account_name = "terraformstatestoragemj"
    container_name       = "tfstate"
    key                  = "bootstrap.terraform.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}