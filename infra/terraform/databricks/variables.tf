variable "databricks_profile" {
  description = "Databricks CLI profile for local runs. Leave null in CI to use environment variables."
  type        = string
  default     = null
}

variable "kafka_bootstrap_servers" {
  description = "Aiven Kafka bootstrap servers (host:port)"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "kafka_ca_pem_path" {
  description = "Local path to the Aiven CA certificate (PEM)"
  type        = string
}

variable "kafka_service_cert_path" {
  description = "Local path to the Aiven service certificate"
  type        = string
}

variable "kafka_service_key_path" {
  description = "Local path to the Aiven service private key"
  type        = string
}

variable "opensky_client_id" {
  description = "OpenSky API client ID"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "opensky_client_secret" {
  description = "OpenSky API client secret"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "kafka_secrets_version" {
  description = "Bump to re-send Kafka secret values (rotation)"
  type        = number
  default     = 1
}

variable "opensky_secrets_version" {
  description = "Bump to re-send OpenSky secret values (rotation)"
  type        = number
  default     = 1
}