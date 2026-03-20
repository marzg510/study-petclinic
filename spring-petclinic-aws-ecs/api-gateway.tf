resource "aws_security_group" "api_gateway" {
  name   = "api-gateway-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/ecs/spring-petclinic-api-gateway"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "spring-petclinic-api-gateway"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    local.otel_sidecar,
    {
      name      = "spring-petclinic-api-gateway"
      image     = "springcommunity/spring-petclinic-api-gateway:latest"
      essential = true
      portMappings = [
        { name = "api-gateway", containerPort = 8080, protocol = "tcp" }
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "docker"
        },
        {
          name  = "SERVER_PORT"
          value = "8080"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/spring-petclinic-api-gateway"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api_gateway" {
  name                   = "api-gateway"
  cluster                = aws_ecs_cluster.main.arn
  task_definition        = aws_ecs_task_definition.api_gateway.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  enable_execute_command             = true
  health_check_grace_period_seconds  = 120

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.api_gateway.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_gateway.arn
    container_name   = "spring-petclinic-api-gateway"
    container_port   = 8080
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.petclinic.arn

    service {
      port_name      = "api-gateway"
      discovery_name = "api-gateway"
      client_alias {
        port     = 8080
        dns_name = "api-gateway"
      }
    }
  }
}