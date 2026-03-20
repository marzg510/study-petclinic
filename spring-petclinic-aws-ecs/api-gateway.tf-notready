resource "aws_service_discovery_service" "api_gateway" {
  name = "api-gateway"
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

  container_definitions = jsonencode([
    {
      name      = "spring-petclinic-api-gateway"
      image     = "springcommunity/spring-petclinic-api-gateway:latest"
      essential = true
      portMappings = [
        { containerPort = 8080, protocol = "tcp" }
      ]
      environment = [
        {
          name  = "SPRING_CONFIG_IMPORT"
          value = "configserver:http://config-server.petclinic.local:8888"
        },
        {
          name  = "SPRING_CLOUD_CONFIG_URI"
          value = "http://config-server.petclinic.local:8888"
        },
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = "ecs"
        },
        {
          name  = "EUREKA_CLIENT_ENABLED"
          value = "false"
        },
        {
          name  = "EUREKA_CLIENT_REGISTER_WITH_EUREKA"
          value = "false"
        },
        {
          name  = "EUREKA_CLIENT_FETCH_REGISTRY"
          value = "false"
        },
        {
          name  = "SPRING_CLOUD_DISCOVERY_ENABLED"
          value = "false"
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
  name            = "api-gateway"
  cluster         = aws_ecs_cluster.main.arn
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.api_gateway.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.api_gateway.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "spring-petclinic-api-gateway"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}
