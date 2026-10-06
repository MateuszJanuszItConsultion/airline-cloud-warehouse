terraform {
  required_version = "~> 1.16"

  backend "azurerm" {}

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.137"
    }
  }
}

provider "databricks" {
  profile = var.databricks_profile
}