data "databricks_current_user" "me" {}

data "databricks_catalogs" "all" {}

data "databricks_catalog" "pilot" {
  name = "tf_pilot"
}

resource "databricks_schema" "pilot" {
  catalog_name  = data.databricks_catalog.pilot.name
  name          = "pilot_schema"
  comment       = "Terraform pilot schema"
  force_destroy = true
}

resource "databricks_volume" "pilot" {
  name         = "pilot_volume"
  catalog_name = data.databricks_catalog.pilot.name
  schema_name  = databricks_schema.pilot.name
  volume_type  = "MANAGED"
}

resource "databricks_grant" "pilot_schema_users" {
  schema     = databricks_schema.pilot.id
  principal  = "account users"
  privileges = ["USE_SCHEMA"]
}

resource "databricks_secret_scope" "pilot" {
  name = "tf-pilot-scope"
}

resource "databricks_secret" "pilot" {
  scope                   = databricks_secret_scope.pilot.name
  key                     = "pilot-key"
  string_value_wo         = var.pilot_secret_value
  string_value_wo_version = 1
}