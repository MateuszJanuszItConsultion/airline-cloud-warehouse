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
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.10"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

provider "azuread" {}