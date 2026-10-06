resource "databricks_grant" "catalog_account_users" {
  catalog    = databricks_catalog.main.name
  principal  = "account users"
  privileges = ["BROWSE"]
}