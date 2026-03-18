data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "main" {
  name = "petclinic"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_private_dns_namespace" "petclinic" {
  name = "petclinic.local"
  vpc  = data.aws_vpc.default.id
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}
