terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "tf-test-vpc" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tf-test-vpc"
  }
}

### Public Subnet 1b
resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.tf-test-vpc.id
  cidr_block              = "10.100.1.0/24"
  availability_zone       = "ap-northeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-test-public-1b"
  }
}

resource "aws_internet_gateway" "tf-test-igw" {
  vpc_id = aws_vpc.tf-test-vpc.id
}

resource "aws_route_table" "tf-test-public" {
  vpc_id = aws_vpc.tf-test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-test-igw.id
  }
}

resource "aws_route_table_association" "tf-test-public_1b" {
  subnet_id      = aws_subnet.public_1b.id
  route_table_id = aws_route_table.tf-test-public.id
}

resource "aws_ecs_cluster" "main" {
  name = "tf-test-cluster"
}



output "vpc_id" {
  value = aws_vpc.tf-test-vpc.id
}

