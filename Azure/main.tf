/*
IPv6 Infrastructure Terraform Deployment for Azure 
Terraform version ~> 2.39
*/

# Configure the Azure Provider for the IPv6 Subscription
provider "azurerm" {
  version         = "=2.39.0"
  features {}
  subscription_id = var.subscription_id
}

#Create the resource group
resource "azurerm_resource_group" "IPv6" {
name     = var.resource_group_name
location = var.location
}

#Create the VNET 
resource "azurerm_virtual_network" "IPv6" {
name                = "IPv6-vnet"
location            = var.location
resource_group_name = azurerm_resource_group.IPv6.name
address_space       = var.vnet_address_space
}

#Create the Adobe IP Subnets
resource "azurerm_subnet" "IPv6-AZ1-Subnet" {
name                 = "IPv6-AZ1-Subnet"
resource_group_name  = azurerm_resource_group.IPv6.name
virtual_network_name = azurerm_virtual_network.IPv6.name
address_prefixes     = var.IPv6-AZ1-Subnet
}




