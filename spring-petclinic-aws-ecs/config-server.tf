resource "aws_service_discovery_service" "config_server" {
  name = "config-server"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.petclinic.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_security_group" "config_server" {
  name   = "config-server-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 8888
    to_port     = 8888
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

resource "aws_cloudwatch_log_group" "config_server" {
  name              = "/ecs/spring-petclinic-config-server"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "config_server" {
  family                   = "spring-petclinic-config-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "spring-petclinic-config-server"
      image     = "springcommunity/spring-petclinic-config-server:latest"
      essential = true
      portMappings = [
        { containerPort = 8888, protocol = "tcp" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/spring-petclinic-config-server"
          awslogs-region        = "ap-northeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "config_server" {
  name            = "config-server"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.config_server.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.config_server.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.config_server.arn
  }
}
