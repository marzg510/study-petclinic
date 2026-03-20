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

resource "aws_security_group" "nginx-test" {
  name   = "nginx-test-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "nginx-test" {
  name              = "/ecs/nginx-test"
  retention_in_days = 1
}

resource "aws_iam_role" "ecs_task_role" {
  name = "nginx-test-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_ssm" {
  name = "nginx-test-task-ssm-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_service_discovery_http_namespace" "main" {
  name = "nginx-test-ns"
}

resource "aws_ecs_cluster" "main" {
  name = "nginx-test"

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.main.arn
  }
}

# ---- nginx-test (service 1) ----

resource "aws_ecs_task_definition" "nginx-test" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx-test"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        { name = "nginx-test", containerPort = 80, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/nginx-test"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "nginx-test" {
  name                   = "nginx-test-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.nginx-test.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.nginx-test.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "nginx-test"
      discovery_name = "nginx-test"
      client_alias {
        port     = 80
        dns_name = "nginx-test"
      }
    }
  }
}

# ---- nginx-test-2 (service 2) ----

resource "aws_cloudwatch_log_group" "nginx-test-2" {
  name              = "/ecs/nginx-test-2"
  retention_in_days = 1
}

resource "aws_security_group" "nginx-test-2" {
  name   = "nginx-test-2-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "nginx-test-2" {
  family                   = "nginx-2"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx-test-2"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        { name = "nginx-test-2", containerPort = 80, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/nginx-test-2"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "nginx-test-2" {
  name                   = "nginx-test-2-service"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.nginx-test-2.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.nginx-test-2.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.main.arn

    service {
      port_name      = "nginx-test-2"
      discovery_name = "nginx-test-2"
      client_alias {
        port     = 80
        dns_name = "nginx-test-2"
      }
    }
  }
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}
