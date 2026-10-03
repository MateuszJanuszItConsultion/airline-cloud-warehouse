# Region intentionally differs from the resource group (polandcentral).
# Azure Free Trial did not allow Automation Accounts in Poland Central,
# so the account was created in North Europe. Changing location forces
# replacement of the account (new identity, runbooks and schedules).
module "vm_scheduler" {
  source              = "../../modules/vm_scheduler"
  location            = "northeurope"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
}