# Both schedules are DISABLED in Azure on purpose: the VM is started and
# stopped manually for now. The azurerm provider has no attribute for the
# enabled/disabled state, so Terraform neither manages nor shows it.
#
# Risk: any change that forces replacement (e.g. start_time) would create
# a NEW schedule, which Azure enables by default - silently re-enabling
# daily VM start/stop. prevent_destroy blocks such replacements.
resource "azurerm_automation_schedule" "start_vm" {
  automation_account_name = azurerm_automation_account.main.name
  expiry_time             = "9999-12-31T23:59:59.9999999+00:00"
  frequency               = "Hour"
  interval                = 24
  name                    = "daily-vm-start"
  resource_group_name     = azurerm_resource_group.main.name
  start_time              = "2026-09-01T07:50:00+02:00"
  timezone                = "Europe/Warsaw"
  lifecycle { prevent_destroy = true }
}

resource "azurerm_automation_schedule" "stop_vm" {
  automation_account_name = azurerm_automation_account.main.name
  expiry_time             = "9999-12-31T23:59:59.9999999+00:00"
  frequency               = "Day"
  interval                = 1
  name                    = "daily-vm-stop"
  resource_group_name     = azurerm_resource_group.main.name
  start_time              = "2026-09-01T08:50:00+02:00"
  timezone                = "Europe/Warsaw"
  lifecycle { prevent_destroy = true }
}

resource "azurerm_automation_job_schedule" "stop_vm" {
  automation_account_name = azurerm_automation_account.main.name
  resource_group_name     = azurerm_resource_group.main.name
  runbook_name            = azurerm_automation_runbook.stop_vm.name
  schedule_name           = azurerm_automation_schedule.stop_vm.name
}

resource "azurerm_automation_job_schedule" "start_vm" {
  automation_account_name = azurerm_automation_account.main.name
  resource_group_name     = azurerm_resource_group.main.name
  runbook_name            = azurerm_automation_runbook.start_vm.name
  schedule_name           = azurerm_automation_schedule.start_vm.name
}

resource "azurerm_automation_account" "main" {
  # Region intentionally differs from the resource group (polandcentral).
  # Azure Free Trial did not allow Automation Accounts in Poland Central,
  # so the account was created in North Europe. Changing location forces
  # replacement of the account (new identity, runbooks and schedules).
  local_authentication_enabled  = true
  location                      = "northeurope"
  name                          = "aa-airline-vm-scheduler"
  public_network_access_enabled = true
  resource_group_name           = azurerm_resource_group.main.name
  sku_name                      = "Basic"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "automation_vm_contributor" {
  name                 = "f5c7c147-b997-4ea5-b576-e3c66a5d202a"
  principal_id         = azurerm_automation_account.main.identity[0].principal_id
  principal_type       = "ServicePrincipal"
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_resource_group.main.id
}

resource "azurerm_automation_runbook" "stop_vm" {
  automation_account_name  = azurerm_automation_account.main.name
  content                  = file("${path.module}/runbooks/Stop-AirflowVM.ps1")
  location                 = azurerm_automation_account.main.location
  log_activity_trace_level = 0
  log_progress             = false
  log_verbose              = false
  name                     = "Stop-AirflowVM"
  resource_group_name      = azurerm_resource_group.main.name
  runbook_type             = "PowerShell72"
}

resource "azurerm_automation_runbook" "start_vm" {
  automation_account_name  = azurerm_automation_account.main.name
  content                  = file("${path.module}/runbooks/Start-AirflowVM.ps1")
  location                 = azurerm_automation_account.main.location
  log_activity_trace_level = 0
  log_progress             = false
  log_verbose              = false
  name                     = "Start-AirflowVM"
  resource_group_name      = azurerm_resource_group.main.name
  runbook_type             = "PowerShell72"
}
