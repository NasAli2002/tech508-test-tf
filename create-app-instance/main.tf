# Where to create - provide cloud service provider
# create an ec2 instance
# which region to use
# which ami to use: AMI ID ami-0c1c30571d2dae5c9 (for ubuntu 22.04 lts)
# type of instance to launch t3.micro
# want to add public IP to instance
# name the instance
 
# This file contains the updated Terraform code that uses variables.
 
# AWS provider configuration
provider "aws" {
  region = var.aws_region
}
 
# Get IP of local machine
data "http" "my_ip" {
url = "https://checkip.amazonaws.com"
}
 
# Format the IP for CIDR
locals {
  my_public_ip_cidr = "${chomp(data.http.my_ip.response_body)}/32"
}
 
# Create a security group
resource "aws_security_group" "allow_ports" {
  name        = var.sg_name
  description = var.sg_description
 
  # Allow SSH from your machine only
  ingress {
    from_port   = var.ssh_app_port
    to_port     = var.ssh_app_port
    protocol    = "tcp"
    cidr_blocks = [local.my_public_ip_cidr]
  }
 
  # Allow application port traffic from anywhere
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow HTTP from anywhere
  ingress {
    from_port   = var.http_app_port
    to_port     = var.http_app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
# Create an EC2 instance
resource "aws_instance" "web" {
  ami                         = var.instance_ami
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = var.key_name
vpc_security_group_ids = [aws_security_group.allow_ports.id]
 
  tags = {
    Name = var.instance_name
  }
}
 
# Output EC2 public IP
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}