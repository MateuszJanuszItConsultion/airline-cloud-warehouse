variable "resource_group_name" {
  type        = string
  description = "Name of the resource group where network resources will be deployed."
}

variable "location" {
  type        = string
  description = "Azure region where network resources will be created."
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet."
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefix for the subnet."
}