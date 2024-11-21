terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 4.16"
    }
    
  }
  required_version = ">= 1.2.0"
}

variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

# define a provider
provider "aws" {
  region     = "eu-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# create a vpc
resource "aws_vpc" "production-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "production-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "production-igw" {
  vpc_id = aws_vpc.production-vpc.id

  tags = {
    Name = "production-igw"
  }
}

# Route Table
resource "aws_route_table" "production-rt" {
  vpc_id = aws_vpc.production-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.production-igw.id
  }

  tags = {
    Name = "production-route-table"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.production-vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1-public"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.production-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2-public"
  }
}

# Route Table Association
resource "aws_route_table_association" "subnet-1-association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.production-rt.id
}

resource "aws_route_table_association" "subnet-2-association" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.production-rt.id
}

resource "aws_security_group" "allow_web_and_ssh_traffic" {
  name        = "allow_web_and_ssh_traffic"
  description = "Allow web and ssh traffic"
  vpc_id      = aws_vpc.production-vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}

locals {
  user_data = <<-EOF
              #!/bin/bash
              # Update packages
              sudo apt-get update -y
              
              # Install Apache2
              sudo apt-get install apache2 -y
              
              # Install Git
              sudo apt-get install git -y

              # Remove default Apache index
              sudo rm /var/www/html/index.html
              
              # Clone the repository 
              cd /var/www/html
              sudo git clone https://github.com/PaulBoye-py/atr-motors-arthurite.git

              # Copy files from atrmotors.com directory to web root
              sudo cp -r atr-motors-arthurite/atrmotors.com/* .
              
              # Clean up the cloned repository
              sudo rm -rf atr-motors-arthurite
              
              # Set correct permissions
              sudo chown -R www-data:www-data /var/www/html
              sudo chmod -R 755 /var/www/html
              
              # Restart Apache
              sudo systemctl restart apache2
              EOF
}

# ... (rest of the configuration remains the same)

# EC2 Instances
resource "aws_instance" "web_server_1" {
  ami                    = "ami-0e8d228ad90af673b"  # Ubuntu 22.04 LTS
  instance_type          = "t2.micro"
  availability_zone      = "eu-west-2a"
  key_name               = "server-key"
  subnet_id              = aws_subnet.subnet-1.id
  vpc_security_group_ids = [aws_security_group.allow_web_and_ssh_traffic.id]
  user_data              = base64encode(local.user_data)

  tags = {
    Name = "Web Server 1"
  }
}

resource "aws_instance" "web_server_2" {
  ami                    = "ami-0e8d228ad90af673b"  # Ubuntu 22.04 LTS
  instance_type          = "t2.micro"
  availability_zone      = "eu-west-2b"
  key_name               = "server-key"
  subnet_id              = aws_subnet.subnet-2.id
  vpc_security_group_ids = [aws_security_group.allow_web_and_ssh_traffic.id]
  user_data              = base64encode(local.user_data)

  tags = {
    Name = "Web Server 2"
  }
}

# Application Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_web_and_ssh_traffic.id]
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]

  tags = {
    Name = "Web Load Balancer"
  }
}

# Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.production-vpc.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "web_server_1_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_server_2_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_server_2.id
  port             = 80
}

# Load Balancer Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Outputs
output "load_balancer_dns" {
  value = aws_lb.web_lb.dns_name
}