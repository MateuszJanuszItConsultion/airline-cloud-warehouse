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

# Data sources for the subscription and resource group
data "azurerm_subscription" "current" {}

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