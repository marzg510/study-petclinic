resource "aws_appautoscaling_target" "api_gateway" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_gateway_scale_out" {
  name               = "api-gateway-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.api_gateway.resource_id
  scalable_dimension = aws_appautoscaling_target.api_gateway.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_gateway.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "api_gateway_scale_in" {
  name               = "api-gateway-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.api_gateway.resource_id
  scalable_dimension = aws_appautoscaling_target.api_gateway.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_gateway.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_cpu_high" {
  alarm_name          = "api-gateway-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api_gateway.name
  }

  alarm_actions = [aws_appautoscaling_policy.api_gateway_scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_cpu_low" {
  alarm_name          = "api-gateway-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.api_gateway.name
  }

  alarm_actions = [aws_appautoscaling_policy.api_gateway_scale_in.arn]
}