# Outputs required for GitHub Actions pipeline configuration (non-secret identifiers)
output "ci_plan_client_id" {
  value       = azuread_service_principal.ci_plan.client_id
  description = "Client ID of the service principal used for Terraform plan execution in GitHub Actions"
}

output "ci_apply_client_id" {
  value       = azuread_service_principal.ci_apply.client_id
  description = "Client ID of the service principal used for Terraform apply execution in GitHub Actions"
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Microsoft Entra ID tenant ID required for OIDC authentication in pipelines"
}