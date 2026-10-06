resource "databricks_catalog" "main" {
  enable_predictive_optimization = "INHERIT"
  force_destroy                  = false
  isolation_mode                 = "ISOLATED"
  name                           = "airline_cloud_warehouse"
  lifecycle {
    # Free Edition: catalog created in UI on Databricks Default Storage.
    # storage_root is platform-assigned and not managed here.
    ignore_changes  = [storage_root]
    prevent_destroy = true
  }
}
resource "databricks_schema" "bronze" {
  catalog_name                   = databricks_catalog.main.name
  enable_predictive_optimization = "INHERIT"
  name                           = "bronze"
}

resource "databricks_schema" "silver" {
  catalog_name                   = databricks_catalog.main.name
  enable_predictive_optimization = "INHERIT"
  name                           = "silver"
}

resource "databricks_schema" "gold" {
  catalog_name                   = databricks_catalog.main.name
  enable_predictive_optimization = "INHERIT"
  name                           = "gold"
}

resource "databricks_volume" "raw_files" {
  catalog_name = databricks_catalog.main.name
  name         = "airline_bronze_raw_files"
  schema_name  = databricks_schema.bronze.name
  volume_type  = "MANAGED"
  lifecycle { prevent_destroy = true }
}

resource "databricks_volume" "streaming_checkpoints" {
  catalog_name = databricks_catalog.main.name
  name         = "streaming_checkpoints"
  schema_name  = databricks_schema.bronze.name
  volume_type  = "MANAGED"
  lifecycle { prevent_destroy = true }
}


