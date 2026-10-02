moved {
  from = azurerm_automation_account.main
  to   = module.vm_scheduler.azurerm_automation_account.main
}

moved {
  from = azurerm_role_assignment.automation_vm_contributor
  to   = module.vm_scheduler.azurerm_role_assignment.automation_vm_contributor
}

moved {
  from = azurerm_automation_schedule.start_vm
  to   = module.vm_scheduler.azurerm_automation_schedule.start_vm
}

moved {
  from = azurerm_automation_schedule.stop_vm
  to   = module.vm_scheduler.azurerm_automation_schedule.stop_vm
}

moved {
  from = azurerm_automation_job_schedule.stop_vm
  to   = module.vm_scheduler.azurerm_automation_job_schedule.stop_vm
}

moved {
  from = azurerm_automation_job_schedule.start_vm
  to   = module.vm_scheduler.azurerm_automation_job_schedule.start_vm
}

moved {
  from = azurerm_automation_runbook.stop_vm
  to   = module.vm_scheduler.azurerm_automation_runbook.stop_vm
}

moved {
  from = azurerm_automation_runbook.start_vm
  to   = module.vm_scheduler.azurerm_automation_runbook.start_vm
}