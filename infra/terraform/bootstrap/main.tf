data "azurerm_client_config" "current" {}

locals {
  common_tags = {
    project    = "airline-cloud-warehouse"
    purpose    = "terraform-state"
    managed_by = "terraform"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "tfstate" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_blob_contributor" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_management_lock" "tfstate" {
  name       = "lock-tfstate-no-delete"
  scope      = azurerm_storage_account.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state for all projects"
}

resource "azurerm_storage_management_policy" "tfstate" {
  storage_account_id = azurerm_storage_account.tfstate.id

  rule {
    name    = "delete-old-versions"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["tfstate/"]
    }

    actions {
      version {
        delete_after_days_since_creation = 90
      }
    }
  }
}