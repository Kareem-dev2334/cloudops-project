terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-2"
  profile = "cloudops-ecr"
}

# ------------------------------------
# VPC
# ------------------------------------

resource "aws_vpc" "cloudops" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "CloudOps-VPC"
  }
}

# ------------------------------------
# PUBLIC SUBNET
# ------------------------------------

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cloudops.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "CloudOps-Public-Subnet"
  }
}

# ------------------------------------
# PRIVATE SUBNET
# ------------------------------------

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.cloudops.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2c"

  tags = {
    Name = "CloudOps-Private-Subnet"
  }
}

# ------------------------------------
# INTERNET GATEWAY
# ------------------------------------

resource "aws_internet_gateway" "cloudops_igw" {
  vpc_id = aws_vpc.cloudops.id

  tags = {
    Name = "CloudOps-IGW"
  }
}

# ------------------------------------
# PUBLIC ROUTE TABLE
# ------------------------------------

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloudops.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudops_igw.id
  }

  tags = {
    Name = "CloudOps-Public-RT"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------
# PRIVATE ROUTE TABLE
# ------------------------------------

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.cloudops.id

  tags = {
    Name = "CloudOps-Private-RT"
  }
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# ------------------------------------
# EXISTING ECS SECURITY GROUP
# ------------------------------------

# Reuse the existing ECS security group.
# Do not create another backend security group.

data "aws_security_group" "existing_ecs_sg" {
  id = "sg-093800cd96c077fcf"
}

# ------------------------------------
# DATABASE SECURITY GROUP
# ------------------------------------

# This security group has already been
# imported into Terraform state.

resource "aws_security_group" "database_sg" {
  name        = "CloudOps-DB-SG"
  description = "Security group for cloudops database"
  vpc_id      = aws_vpc.cloudops.id
}

# ------------------------------------
# MYSQL INGRESS
# ECS BACKEND -> DATABASE
# ------------------------------------

resource "aws_vpc_security_group_ingress_rule" "mysql_from_backend" {
  security_group_id = aws_security_group.database_sg.id

  referenced_security_group_id = data.aws_security_group.existing_ecs_sg.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306
}

# ------------------------------------
# MYSQL EGRESS
# ECS BACKEND -> DATABASE
# ------------------------------------

resource "aws_vpc_security_group_egress_rule" "backend_to_database" {
  security_group_id = data.aws_security_group.existing_ecs_sg.id

  referenced_security_group_id = aws_security_group.database_sg.id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306
}
