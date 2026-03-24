resource "aws_security_group" "tf-test-nginx" {
  name   = "tf-test-nginx-sg"
  vpc_id = aws_vpc.tf-test-vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["163.116.208.22/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_cloudwatch_log_group" "tf-test-nginx" {
#   name              = "/ecs/tf-test-nginx"
#   retention_in_days = 1
# }

resource "aws_ecs_task_definition" "tf-test-nginx" {
  family                   = "tf-test-nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  # task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "tf-test-nginx"
      image     = "public.ecr.aws/nginx/nginx:latest"
      essential = true
      portMappings = [
        { name = "nginx", containerPort = 80, protocol = "tcp" }
      ]
      # logConfiguration = {
      #   logDriver = "awslogs"
      #   options = {
      #     awslogs-group         = "/ecs/tf-test-nginx"
      #     awslogs-region        = "ap-northeast-1"
      #     awslogs-stream-prefix = "ecs"
      #   }
      # }
    }
  ])
}

resource "aws_ecs_service" "tf-test-nginx" {
  name                   = "tf-test-nginx"
  cluster                = aws_ecs_cluster.main.arn
  task_definition        = aws_ecs_task_definition.tf-test-nginx.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  # enable_execute_command             = true
  health_check_grace_period_seconds  = 120

  network_configuration {
    subnets          = [aws_subnet.public_1b.id]
    security_groups  = [aws_security_group.tf-test-nginx.id]
    assign_public_ip = true
  }
}
