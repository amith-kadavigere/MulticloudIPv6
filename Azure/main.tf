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

#Create the NSG
resource "azurerm_network_security_group" "IPv6-nsg" {
  name                = "IPv6-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.IPv6.name

  security_rule {
  name                       = "Port_80"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix    = "*"
  destination_address_prefix = "*"
  }
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

    //IPv4 attachment
    frontend_ip_configuration {
        name                 = "IPv6-v4PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.IPv4_Public_IP.id
        private_ip_address_version = "IPv4"
    }

    //IPv6 attachment
    frontend_ip_configuration {
        name                 = "IPv6-v6PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.IPv6_Public_IP.id
        private_ip_address_version = "IPv6"
    }
}

#Create the LB Backend Address Pools for IPv4 and IPv6
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

#Create the Health Probe, this will work for both IPv6 and IPv6. For better metrics create a seperate one for IPv4 and IPv6. 
resource "azurerm_lb_probe" "IPv6_Probe" {
    resource_group_name = azurerm_resource_group.IPv6.name
    loadbalancer_id     = azurerm_lb.IPv6lb.id
    name                = "IPv6_Probe"
    port                = 80
}

#Create the LB Rules for IPv4 and IPv6
resource "azurerm_lb_rule" "IPv6_rule_port80v4" {
  resource_group_name            = azurerm_resource_group.IPv6.name
  loadbalancer_id                = azurerm_lb.IPv6lb.id
  name                           = "IPv6_rule_80v4"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.IPv4_Backend_Pool.id
  frontend_ip_configuration_name = "IPv6-v4PublicIPAddress"
  probe_id                       = azurerm_lb_probe.IPv6_Probe.id
}

resource "azurerm_lb_rule" "IPv6_rule_port80v6" {
  resource_group_name            = azurerm_resource_group.IPv6.name
  loadbalancer_id                = azurerm_lb.IPv6lb.id
  name                           = "IPv6_rule_80v6"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.IPv6_Backend_Pool.id
  frontend_ip_configuration_name = "IPv6-v6PublicIPAddress"
  probe_id                       = azurerm_lb_probe.IPv6_Probe.id
}

#Create a zone balances scale set. 
resource "azurerm_linux_virtual_machine_scale_set" "IPv6_Scaleset" {
    name                = "IPv6Node"
    resource_group_name = azurerm_resource_group.IPv6.name
    location            = var.location
    sku                 = "Standard_F2"
    instances           = 3
    zones               = ["1", "2", "3"]
    zone_balance        = "true"
    custom_data         = base64encode(file("web.conf"))
    disable_password_authentication = "true"
    admin_username      = "azureuser"

    admin_ssh_key {
        username   = "azureuser"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    #This will create a network interface per instance in the scale set. This interface is Network Accelerated as well 
    network_interface {
        name    = "ipv6ssinterface"
        primary = "true"
        enable_accelerated_networking = "true"
        network_security_group_id = azurerm_network_security_group.IPv6-nsg.id

        #This IP configuration for the IPv4 address this will be set to Primary 
        ip_configuration {
            name      = "v4config"
            version   = "IPv4"
            primary   = "true"
            subnet_id = azurerm_subnet.IPv6-Subnet.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.IPv4_Backend_Pool.id]
        }

        #This IP configuration for the IPv6 address 
        ip_configuration {
            name      = "v6config"
            version   = "IPv6"
            subnet_id = azurerm_subnet.IPv6-Subnet.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.IPv6_Backend_Pool.id]
        }
    }
}






