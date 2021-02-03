#Location and Zone Variables
#Region Selection
variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

#Choosing the AZ's to use in the region
variable "az1" {
  description = "AZ Infomration"
  default     = "us-east-1a"
}

variable "az2" {
  description = "AZ Infomration"
  default     = "us-east-1b"
}

variable "az3" {
  description = "AZ Infomration"
  default     = "us-east-1c"
}

#Network Variables 
#Overall IPv4 Space for the VPC
variable "cidr" {
  description = "VPC IPv4 CIDR Block"
  default     = "10.0.0.0/16"
}

#Public IPv4 Subnet Space
variable "pubsubnet1" {
  description = "IPv4 Public Subnet"
  default     = "10.0.1.0/24"
}

variable "pubsubnet2" {
  description = "IPv4 Public Subnet"
  default     = "10.0.2.0/24"
}

variable "pubsubnet3" {
  description = "IPv4 Public Subnet"
  default     = "10.0.3.0/24"
}

#Private IPv6 Subnet space
variable "privsubnet1" {
  description = "IPv4 Private Subnet"
  default     = "10.0.4.0/24"
}

variable "privsubnet2" {
  description = "IPv4 Private Subnet"
  default     = "10.0.5.0/24"
}

variable "privsubnet3" {
  description = "IPv4 Private Subnet"
  default     = "10.0.6.0/24"
}

#Compute Variables
#Key to use 
variable "key_name" {
  description = "Key to use on instaces"
  default     = "IPv6"
}

#Instance Type Selection, using the new Graviton 2 arm instance, for more on Graviton 2: https://aws.amazon.com/ec2/graviton/
variable "ipv6_instance_type" {
  description = "What instance size to use"
  default     = "m6g.medium"
}

#ami selection by region for current list reference https://cloud-images.ubuntu.com/locator/ec2/
variable "ipv6_aws_amis" {
  default = {
    #Using ARM based ami to take advantage of Graviton 2 
    "us-east-1" = "ami-0b82a18ec136832aa"
    "us-west-2" = "ami-0689b1146b144630a"
  }
}



