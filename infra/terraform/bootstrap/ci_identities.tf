locals {
  github_oidc_issuer    = "https://token.actions.githubusercontent.com"
  azure_ad_audience     = "api://AzureADTokenExchange"
  github_subject_prefix = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_repository_name}@${var.github_repository_id}"

}

# --- Plan identity: read-only, trusted for pull requests only ---

resource "azuread_application" "ci_plan" {
  display_name = "gh-airline-terraform-plan"
}

resource "azuread_service_principal" "ci_plan" {
  client_id = azuread_application.ci_plan.client_id
}

resource "azuread_application_federated_identity_credential" "ci_plan_pr" {
  application_id = azuread_application.ci_plan.id
  display_name   = "github-pull-request"
  description    = "Terraform plan on pull requests"
  issuer         = local.github_oidc_issuer
  audiences      = [local.azure_ad_audience]
  subject        = "${local.github_subject_prefix}:pull_request"
}

# --- Apply identity: write access, trusted for the production environment only ---

resource "azuread_application" "ci_apply" {
  display_name = "gh-airline-terraform-apply"
}

resource "azuread_service_principal" "ci_apply" {
  client_id = azuread_application.ci_apply.client_id
}

# Data sources for the subscription and resource group
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "prod" {
  name = "rg-airline-data-engineering"
}

resource "azuread_application_federated_identity_credential" "ci_apply_production" {
  application_id = azuread_application.ci_apply.id
  display_name   = "github-environment-production"
  description    = "Terraform apply from the production environment"
  issuer         = local.github_oidc_issuer
  audiences      = [local.azure_ad_audience]
  subject        = "${local.github_subject_prefix}:environment:production"
}

# 1. Plan: Reader role at the subscription scope
resource "azurerm_role_assignment" "plan_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.ci_plan.object_id
}

# 2. Plan: read-only access to state blobs.
# Intentionally NOT Contributor: the plan identity runs code from unreviewed
# pull requests and must not be able to overwrite or delete state.
# Consequence: CI runs `terraform plan -lock=false` (Reader cannot acquire
# the blob lease). Locking is always used for apply.
resource "azurerm_role_assignment" "plan_state_blob" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.ci_plan.object_id
}

# 3. Apply: Contributor role at the subscription scope 
# (Note: Conscious simplification; in a single-subscription project this is acceptable, 
# but in a production environment you would narrow this scope to specific resource groups and budgets)
resource "azurerm_role_assignment" "apply_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.ci_apply.object_id
}

# 4. Apply: Role Based Access Control Administrator on the resource group 
# (Required for managing roles e.g., for the Automation identity)
resource "azurerm_role_assignment" "apply_rbac_admin" {
  scope                = data.azurerm_resource_group.prod.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.ci_apply.object_id
}

# 5. Apply: Storage Blob Data Contributor on the state storage account
resource "azurerm_role_assignment" "apply_state_blob" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.ci_apply.object_id
}