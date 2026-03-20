resource "aws_security_group" "vets_service" {
  name   = "vets-service-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 8083
    to_port     = 8083
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

resource "aws_cloudwatch_log_group" "vets_service" {
  name              = "/ecs/spring-petclinic-vets-service"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "vets_service" {
  family                   = "spring-petclinic-vets-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "spring-petclinic-vets-service"
      image     = "springcommunity/spring-petclinic-vets-service:latest"
      essential = true
      portMappings = [
        { name = "vets-service", containerPort = 8083, protocol = "tcp" }
      ]
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "docker,mysql"
        },
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.petclinic.endpoint
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.db_password
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/spring-petclinic-vets-service"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "vets_service" {
  name                   = "vets-service"
  cluster                = aws_ecs_cluster.main.arn
  task_definition        = aws_ecs_task_definition.vets_service.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.vets_service.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled   = true
    namespace = aws_service_discovery_http_namespace.petclinic.arn

    service {
      port_name      = "vets-service"
      discovery_name = "vets-service"
      client_alias {
        port     = 8083
        dns_name = "vets-service"
      }
    }
  }
}