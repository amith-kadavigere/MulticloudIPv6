#Subscription ID
variable "subscription_id"{
  description = "Subscription ID used for this deployment"  
}

#Resource Group Name
variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = "IPv6"
}

#Location 
variable "location" {
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created. Please review the Hosting Standard to select a approved location"
  default     = "eastus2"
}

#Overall IPv4 and IPv6 Space for the VNET
variable "vnet_address_space" {
  description = "The address space of the VNET"
  default = ["10.0.0.0/16","fd00:db8:deca::/48"]
}

#IPv4 and ipV6 Space allocated for Subnet 
variable "IPv6-Subnet" {
  description = "The subnet to be used"
  default = ["10.0.1.0/24","fd00:db8:deca:daed::/64"]
}

