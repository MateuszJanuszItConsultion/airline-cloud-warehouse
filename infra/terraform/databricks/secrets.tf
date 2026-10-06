resource "databricks_secret_scope" "kafka_aiven" {
  name = "kafka-aiven"
}

resource "databricks_secret_scope" "opensky" {
  name = "opensky"
}

locals {
  kafka_secret_values = {
    bootstrap_servers = var.kafka_bootstrap_servers
    ca_pem            = file(var.kafka_ca_pem_path)
    service_cert      = file(var.kafka_service_cert_path)
    service_key       = file(var.kafka_service_key_path)
  }

  opensky_secret_values = {
    client_id     = var.opensky_client_id
    client_secret = var.opensky_client_secret
  }
}

# Keys are listed explicitly: for_each cannot iterate over a collection
# derived from sensitive or ephemeral values.
resource "databricks_secret" "kafka_aiven" {
  for_each = toset(["bootstrap_servers", "ca_pem", "service_cert", "service_key"])

  scope                   = databricks_secret_scope.kafka_aiven.name
  key                     = each.key
  string_value_wo         = local.kafka_secret_values[each.key]
  string_value_wo_version = var.kafka_secrets_version
}

resource "databricks_secret" "opensky" {
  for_each = toset(["client_id", "client_secret"])

  scope                   = databricks_secret_scope.opensky.name
  key                     = each.key
  string_value_wo         = local.opensky_secret_values[each.key]
  string_value_wo_version = var.opensky_secrets_version
}