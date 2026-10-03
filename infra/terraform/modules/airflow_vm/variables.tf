variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where VM resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region where VM resources will be created."
}

variable "subnet_id" {
  type        = string
  description = "The ID of the primary subnet used for network interfaces and virtual machine deployment."
}

variable "admin_username" {
  type        = string
  description = "The admin username for the virtual machine."
  sensitive   = true
}

variable "ssh_allowed_source_ip" {
  type        = string
  description = "The source IP address or CIDR block allowed to access the virtual machine via SSH."
  sensitive   = true
}
