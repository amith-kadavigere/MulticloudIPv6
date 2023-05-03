/*
IPv6 Infrastructure Terraform Deployment for AWS
Terraform version ~> v0.14
*/

#Region Selection
provider "aws" {
  region = var.aws_region
}

#Create the IPv6 VPC
resource "aws_vpc" "ipv6_vpc" {
  cidr_block       = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "ipv6_vpc"

  }
}

#Create 3 Public Subnets in each AZ 
resource "aws_subnet" "public_ipv6_subnet_1" {
  vpc_id     = aws_vpc.ipv6_vpc.id
  cidr_block = var.pubsubnet1
  availability_zone = var.az1

  ipv6_cidr_block = cidrsubnet(aws_vpc.ipv6_vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch = false

  tags = {
    Name = "public_ipv6_subnet_1"
  }
}

# resource "aws_subnet" "public_ipv6_subnet_2" {
#   vpc_id     = aws_vpc.ipv6_vpc.id
#   cidr_block = var.pubsubnet2
#   availability_zone = var.az2

#   ipv6_cidr_block = cidrsubnet(aws_vpc.ipv6_vpc.ipv6_cidr_block, 8, 2)
#   assign_ipv6_address_on_creation = false
#   map_public_ip_on_launch = false

#   tags = {
#     Name = "public_ipv6_subnet_2"
#   }
# }

# resource "aws_subnet" "public_ipv6_subnet_3" {
#   vpc_id     = aws_vpc.ipv6_vpc.id
#   cidr_block = var.pubsubnet3
#   availability_zone = var.az3

#   ipv6_cidr_block = cidrsubnet(aws_vpc.ipv6_vpc.ipv6_cidr_block, 8, 3)
#   assign_ipv6_address_on_creation = false
#   map_public_ip_on_launch = false

#   tags = {
#     Name = "public_ipv6_subnet_3"
#   }
# }

#Create 3 Private Subnets in each AZ 
resource "aws_subnet" "private_ipv6_subnet_1" {
  vpc_id     = aws_vpc.ipv6_vpc.id
  cidr_block = var.privsubnet1
  availability_zone = var.az1

  map_public_ip_on_launch = false

  tags = {
    Name = "private_ipv6_subnet_1"
  }
}

# resource "aws_subnet" "private_ipv6_subnet_2" {
#   vpc_id     = aws_vpc.ipv6_vpc.id
#   cidr_block = var.privsubnet2
#   availability_zone = var.az2

#   map_public_ip_on_launch = false

#   tags = {
#     Name = "private_ipv6_subnet_2"
#   }
# }

# resource "aws_subnet" "private_ipv6_subnet_3" {
#   vpc_id     = aws_vpc.ipv6_vpc.id
#   cidr_block = var.privsubnet3
#   availability_zone = var.az3

#   map_public_ip_on_launch = false

#   tags = {
#     Name = "private_ipv6_subnet_3"
#   }
# }

#Create the Internet Gateway 
resource "aws_internet_gateway" "ipv6_vpc_igw" {
  vpc_id = aws_vpc.ipv6_vpc.id

  tags = {
    Name = "ipv6_vpc_igw"
  }
}

#Create the Route Table
resource "aws_route_table" "ipv6_public_rt" {
    vpc_id = aws_vpc.ipv6_vpc.id

    #Set the default IPv4 route to use the Internet Gateway 
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ipv6_vpc_igw.id
    }

    #Set the default IPv6 route to use the Internet Gateway 
    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.ipv6_vpc_igw.id
    }

    tags = {
        Name = "ipv6_public_rt"
    }
}

#Associate the route with Public Subnet 1
resource "aws_route_table_association" "ipv6_ra_public_1" {
    subnet_id = aws_subnet.public_ipv6_subnet_1.id
    route_table_id = aws_route_table.ipv6_public_rt.id
}

# #Associate the route with Public Subnet 2
# resource "aws_route_table_association" "ipv6_ra_public_2" {
#     subnet_id = aws_subnet.public_ipv6_subnet_2.id
#     route_table_id = aws_route_table.ipv6_public_rt.id
# }

# #Associate the route with Public Subnet 3
# resource "aws_route_table_association" "ipv6_ra_public_3" {
#     subnet_id = aws_subnet.public_ipv6_subnet_3.id
#     route_table_id = aws_route_table.ipv6_public_rt.id
# }

#Create 3 NAT Gateways for the Private Subnet instaces
#Create EIP for each Gateway
resource "aws_eip" "nat_gateway_1" {
  vpc = true
}

# resource "aws_eip" "nat_gateway_2" {
#   vpc = true
# }

# resource "aws_eip" "nat_gateway_3" {
#   vpc = true
# }

#Create the 3 Gateways and place them in each public subnet
resource "aws_nat_gateway" "ipv6_nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_ipv6_subnet_1.id
  tags = {
    "Name" = "ipv6_nat_gateway_1"
  }
}

# resource "aws_nat_gateway" "ipv6_nat_gateway_2" {
#   allocation_id = aws_eip.nat_gateway_2.id
#   subnet_id = aws_subnet.public_ipv6_subnet_2.id
#   tags = {
#     "Name" = "ipv6_nat_gateway_2"
#   }
# }

# resource "aws_nat_gateway" "ipv6_nat_gateway_3" {
#   allocation_id = aws_eip.nat_gateway_3.id
#   subnet_id = aws_subnet.public_ipv6_subnet_3.id
#   tags = {
#     "Name" = "ipv6_nat_gateway_3"
#   }
# }

#Create a route table for the 3 private subnets and make the defauly route the nat gateway 
resource "aws_route_table" "ipv6_private_rt_1" {
  vpc_id = aws_vpc.ipv6_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ipv6_nat_gateway_1.id
  }
  tags = {
        Name = "ipv6_private_rt_1"
  }
}

# resource "aws_route_table" "ipv6_private_rt_2" {
#   vpc_id = aws_vpc.ipv6_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.ipv6_nat_gateway_2.id
#   }
#     tags = {
#         Name = "ipv6_private_rt_2"
#     }
# }

# resource "aws_route_table" "ipv6_private_rt_3" {
#   vpc_id = aws_vpc.ipv6_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.ipv6_nat_gateway_3.id
#   }
#     tags = {
#         Name = "ipv6_private_rt_3"
#     }
# }

#Associate the route table to each private subnet 
resource "aws_route_table_association" "ipv6_ra_private_1" {
  subnet_id = aws_subnet.private_ipv6_subnet_1.id
  route_table_id = aws_route_table.ipv6_private_rt_1.id
}

# resource "aws_route_table_association" "ipv6_ra_private_2" {
#   subnet_id = aws_subnet.private_ipv6_subnet_2.id
#   route_table_id = aws_route_table.ipv6_private_rt_2.id
# }

# resource "aws_route_table_association" "ipv6_ra_private_3" {
#   subnet_id = aws_subnet.private_ipv6_subnet_3.id
#   route_table_id = aws_route_table.ipv6_private_rt_3.id
# }

#IPv4 and IPv6 Security Group for Auto Scale Group
#Allow Traffic in from Public Subnet and all traffic out 
resource "aws_security_group" "ipv6_allow_sg" {
  name        = "ipv6_allow_sg"
  description = "Allow connections from public subnet"
  vpc_id = aws_vpc.ipv6_vpc.id

  #Allow HTTP Traffic from anywhere for IPv4
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  #Allow All Traffic from the VPC CIDR for IPv4
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks     = [var.cidr]
  }

  #Allow all traffic out 
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#Create the NLB
resource "aws_lb" "ipv6-01-nlb" {
  name = "ipv6-nlb"
  internal           = false
  load_balancer_type = "network"
  ip_address_type = "dualstack"

  enable_cross_zone_load_balancing = true

  subnets = [
    aws_subnet.public_ipv6_subnet_1.id,
    aws_subnet.public_ipv6_subnet_2.id,
    aws_subnet.public_ipv6_subnet_3.id
  ]
}

#Create the NLB Listener for port 80
resource "aws_lb_listener" "ipv6-nlb-lis-80" {
  load_balancer_arn = aws_lb.ipv6-01-nlb.arn
  port = 80
  protocol = "TCP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ipv6-01-nlb-tg-80.arn
  }
}

#Create the Target Group
resource "aws_lb_target_group" "ipv6-01-nlb-tg-80" {
  name = "ipv6-nlb-tg-80"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.ipv6_vpc.id
  target_type = "instance"
  deregistration_delay = 90

  #Create the health check 
  health_check {
    interval = 10
    port = 80
    protocol = "TCP"
    healthy_threshold = 3
    unhealthy_threshold = 3
  }
}

#Grabbing the YAML file
data "template_file" "ipv6_user_data" {
  template = file("web.yaml")
}

#Define the Instance base launch config for the ASG instances
resource "aws_launch_configuration" "ipv6_lc" {
  name_prefix = "ipv6"
  image_id = var.ipv6_aws_amis[var.aws_region]
  instance_type = var.ipv6_instance_type
  key_name = var.key_name

  security_groups = [ aws_security_group.ipv6_allow_sg.id ]

  user_data = data.template_file.ipv6_user_data.rendered
}

#Create the Autoscaling Group
resource "aws_autoscaling_group" "ipv6_asg" {
  name = "ipv6-asg"

  min_size             = 1
  desired_capacity     = 2
  max_size             = 3
  
  health_check_type = "EC2"

  depends_on        = [aws_nat_gateway.ipv6_nat_gateway_1,aws_nat_gateway.ipv6_nat_gateway_2,aws_nat_gateway.ipv6_nat_gateway_3]


  launch_configuration = aws_launch_configuration.ipv6_lc.name

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  vpc_zone_identifier  = [
    aws_subnet.private_ipv6_subnet_1.id
    # aws_subnet.private_ipv6_subnet_2.id,
    # aws_subnet.private_ipv6_subnet_3.id
  ]

  #Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
    ignore_changes = [ target_group_arns ]
  }

  tag {
    key                 = "Name"
    value               = "ipv6"
    propagate_at_launch = true
  }
}

#Attach the asg instaces to the LB Target Group
resource "aws_autoscaling_attachment" "ipv6-asa-80" {
  autoscaling_group_name = aws_autoscaling_group.ipv6_asg.id
  alb_target_group_arn = aws_lb_target_group.ipv6-01-nlb-tg-80.arn
}