terraform {
  required_version = "~> 1.16"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.134"
    }
  }
}

provider "databricks" {
  profile = var.databricks_profile
}