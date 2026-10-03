module "airflow_vm" {
  source                = "../../modules/airflow_vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  ssh_allowed_source_ip = var.ssh_allowed_source_ip
  subnet_id             = module.network.subnet_id
  admin_username        = var.admin_username
}