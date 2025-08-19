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
 
# Find the existing VPC and Subnet created by the controller
# Terraform will find the resources by their tags
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["terraform-ansible-vpc-naseem"]
  }
}
 
data "aws_subnet" "existing_subnet" {
  filter {
    name   = "tag:Name"
    values = ["terraform-ansible-subnet-naseem"]
  }
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
 
# Create a security group for the DB node (SSH and Mongo DB port)
resource "aws_security_group" "db_node_sg" {
  name        = "db-node-sg"
  description = "Allow SSH and Mongo DB port"
  vpc_id      = data.aws_vpc.existing_vpc.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 27017
    to_port     = 27017
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
    Name = "db-node-sg"
  }
}
 
# Create the DB node instance
resource "aws_instance" "db_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "tech508-naseem-aws" # Key pair filled in
  subnet_id     = data.aws_subnet.existing_subnet.id
 
  vpc_security_group_ids = [aws_security_group.db_node_sg.id]
 
  tags = {
    Name = "tech508-naseem-ubuntu-2204-ansible-target-node-db" 
  }
}
 
 