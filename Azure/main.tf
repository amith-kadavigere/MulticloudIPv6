/*
IPv6 Infrastructure Terraform Deployment for Azure 
Terraform version ~> 2.39
*/

# Configure the Azure Provider for the IPv6 Subscription
provider "azurerm" {
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

#Create the Subnet
resource "azurerm_subnet" "IPv6-Subnet" {
    name                 = "IPv6-Subnet"
    resource_group_name  = azurerm_resource_group.IPv6.name
    virtual_network_name = azurerm_virtual_network.IPv6.name
    address_prefixes     = var.IPv6-Subnet
}

#Create a v4 Public IP
resource "azurerm_public_ip" "IPv4_Public_IP" {
    name                = "IPv4-LoadBalancer-IP"
    location            = var.location
    resource_group_name = azurerm_resource_group.IPv6.name
    sku                 = "Standard"
    allocation_method   = "Static"
    ip_version = "IPv4"
    domain_name_label   = "ipv6azlb1"
}

#Create a v6 Public IP
resource "azurerm_public_ip" "IPv6_Public_IP" {
    name                = "IPv6-LoadBalancer-IP"
    location            = var.location
    resource_group_name = azurerm_resource_group.IPv6.name
    sku                 = "Standard"
    allocation_method   = "Static"
    ip_version = "IPv6"
    domain_name_label   = "ipv6azlb1"
}

#Create the Load Balancer and attach the Public IP
resource "azurerm_lb" "IPv6lb" {
    name                = "IPv6-LoadBalancer"
    location            = var.location
    sku                 = "Standard"
    resource_group_name = azurerm_resource_group.IPv6.name

    frontend_ip_configuration {
        name                 = "IPv6-v4PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.IPv4_Public_IP.id
        private_ip_address_version = "IPv4"
    }

    frontend_ip_configuration {
        name                 = "IPv6-v6PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.IPv6_Public_IP.id
        private_ip_address_version = "IPv6"
    }
}

#Create the LB Rule
resource "azurerm_lb_rule" "IPv6_rule_port80v4" {
  resource_group_name            = azurerm_resource_group.IPv6.name
  loadbalancer_id                = azurerm_lb.IPv6lb.id
  name                           = "IPv6_rule_80v4"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "IPv6-v4PublicIPAddress"
}

resource "azurerm_lb_rule" "IPv6_rule_port80v6" {
  resource_group_name            = azurerm_resource_group.IPv6.name
  loadbalancer_id                = azurerm_lb.IPv6lb.id
  name                           = "IPv6_rule_80v6"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "IPv6-v6PublicIPAddress"
}

#Create the LB Backend Address Pool
resource "azurerm_lb_backend_address_pool" "IPv4_Backend_Pool" {
    resource_group_name = azurerm_resource_group.IPv6.name
    loadbalancer_id     = azurerm_lb.IPv6lb.id
    name                = "IPv4_Backend_Pool"
}

resource "azurerm_lb_backend_address_pool" "IPv6_Backend_Pool" {
    resource_group_name = azurerm_resource_group.IPv6.name
    loadbalancer_id     = azurerm_lb.IPv6lb.id
    name                = "IPv6_Backend_Pool"
}

#Create the Health Probe 
resource "azurerm_lb_probe" "IPv6_Probe" {
    resource_group_name = azurerm_resource_group.IPv6.name
    loadbalancer_id     = azurerm_lb.IPv6lb.id
    name                = "IPv6_Probe"
    port                = 80
}

#Create the Scale Set 
resource "azurerm_linux_virtual_machine_scale_set" "IPv6_Scaleset" {
    name                = "IPv6Node"
    resource_group_name = azurerm_resource_group.IPv6.name
    location            = var.location
    sku                 = "Standard_F2"
    instances           = 3
    zones               = ["1", "2", "3"]
    zone_balance        = "true"
    custom_data         = base64encode("cloud-init.txt")
    disable_password_authentication = "false"
    admin_username      = "azureuser"
    admin_password = "Ipv6Test123456789"


    

    admin_ssh_key {
        username   = "adminuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    network_interface {
        name    = "scalesetint"
        primary = "true"
        enable_accelerated_networking = "true"

        ip_configuration {
            name      = "v4config"
            version   = "IPv4"
            primary   = "true"
            subnet_id = azurerm_subnet.IPv6-Subnet.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.IPv4_Backend_Pool.id]
        }

        ip_configuration {
            name      = "v6config"
            version   = "IPv6"
            subnet_id = azurerm_subnet.IPv6-Subnet.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.IPv6_Backend_Pool.id]
        }
    }
}






