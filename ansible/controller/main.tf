# Define the AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
 
provider "aws" {
  region = "eu-west-1" # Corrected region
}
 
# Find the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  owners = ["099720109477"] # Canonical
}
 
# --- CREATE A NEW VPC AND SUBNET ---
# This code creates the network environment that was missing.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform-ansible-vpc-naseem"
  }
}
 
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # Allows instances in this subnet to get a public IP
  tags = {
    Name = "terraform-ansible-subnet-naseem"
  }
}
 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "terraform-ansible-igw"
  }
}
 
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "terraform-ansible-route-table"
  }
}
 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.route.id
}
 
# Create a security group for the controller (allows SSH)
resource "aws_security_group" "ansible_controller_sg" {
  name        = "ansible-controller-sg"
  description = "Allow SSH access to the Ansible Controller"
  vpc_id      = aws_vpc.main.id
 
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "ansible-controller-sg"
  }
}
 
# Create the controller instance
resource "aws_instance" "ansible_controller" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "tech508-naseem-aws" # Key pair filled in
  subnet_id     = aws_subnet.main.id
  
  vpc_security_group_ids = [aws_security_group.ansible_controller_sg.id]
 
  tags = {
    Name = "tech508-naseem-ubuntu-2204-ansible-controller"
  }
}
 
# Output the public IP to easily SSH into it later
output "controller_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}
 