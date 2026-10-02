resource "azurerm_public_ip" "vm" {
  name                    = "vm-airline-airflow-ip"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  sku                     = "Standard"
  sku_tier                = "Regional"
  ip_version              = "IPv4"
  idle_timeout_in_minutes = 4
  ddos_protection_mode    = "VirtualNetworkInherited"
}

resource "azurerm_network_security_group" "vm" {
  name                = "vm-airline-airflow-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_source_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm" {
  name                           = "vm-airline-airflow799"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  accelerated_networking_enabled = false
  ip_forwarding_enabled          = false

  ip_configuration {
    name                          = "ipconfig1"
    primary                       = true
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-airline-airflow"
  computer_name       = "vm-airline-airflow"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = "Standard_B2as_v2"

  network_interface_ids = [azurerm_network_interface.vm.id]

  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxhgEYMw7eWI5WD12CEg4yzfW5it/okNESHxk6Af966 generated-by-azure"
  }

  os_disk {
    name                      = "vm-airline-airflow_disk1_3c58758d093a47d99a6bd06880ff71a0"
    caching                   = "ReadWrite"
    storage_account_type      = "StandardSSD_LRS"
    disk_size_gb              = 30
    write_accelerator_enabled = false
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {}

  additional_capabilities {
    hibernation_enabled = false
    ultra_ssd_enabled   = false
  }

  priority                                               = "Regular"
  provision_vm_agent                                     = true
  allow_extension_operations                             = true
  extensions_time_budget                                 = "PT1H30M"
  patch_mode                                             = "ImageDefault"
  patch_assessment_mode                                  = "ImageDefault"
  bypass_platform_safety_checks_on_user_schedule_enabled = false
  disk_controller_type                                   = "SCSI"
  encryption_at_host_enabled                             = false
  secure_boot_enabled                                    = false
  vtpm_enabled                                           = false

  lifecycle {
    prevent_destroy = true
  }
}