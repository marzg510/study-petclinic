resource "aws_appautoscaling_target" "api_gateway" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# リクエスト数ベースのスケーリング（TargetTracking）
# タスクあたり100 req/分を超えたらスケールアウト
resource "aws_appautoscaling_policy" "api_gateway_request_count" {
  name               = "api-gateway-request-count"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api_gateway.resource_id
  scalable_dimension = aws_appautoscaling_target.api_gateway.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api_gateway.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 100
    scale_in_cooldown  = 120
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.petclinic.arn_suffix}/${aws_lb_target_group.api_gateway.arn_suffix}"
    }
  }
}

# CPUベースのスケーリング（StepScaling）
# CPU 70%超でスケールアウト、30%未満でスケールイン
#
# resource "aws_appautoscaling_policy" "api_gateway_scale_out" {
#   name               = "api-gateway-scale-out"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.api_gateway.resource_id
#   scalable_dimension = aws_appautoscaling_target.api_gateway.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.api_gateway.service_namespace
#
#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 60
#     metric_aggregation_type = "Average"
#
#     step_adjustment {
#       metric_interval_lower_bound = 0
#       scaling_adjustment          = 1
#     }
#   }
# }
#
# resource "aws_appautoscaling_policy" "api_gateway_scale_in" {
#   name               = "api-gateway-scale-in"
#   policy_type        = "StepScaling"
#   resource_id        = aws_appautoscaling_target.api_gateway.resource_id
#   scalable_dimension = aws_appautoscaling_target.api_gateway.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.api_gateway.service_namespace
#
#   step_scaling_policy_configuration {
#     adjustment_type         = "ChangeInCapacity"
#     cooldown                = 120
#     metric_aggregation_type = "Average"
#
#     step_adjustment {
#       metric_interval_upper_bound = 0
#       scaling_adjustment          = -1
#     }
#   }
# }
#
# resource "aws_cloudwatch_metric_alarm" "api_gateway_cpu_high" {
#   alarm_name          = "api-gateway-cpu-high"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 2
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = 60
#   statistic           = "Average"
#   threshold           = 70
#
#   dimensions = {
#     ClusterName = aws_ecs_cluster.main.name
#     ServiceName = aws_ecs_service.api_gateway.name
#   }
#
#   alarm_actions = [aws_appautoscaling_policy.api_gateway_scale_out.arn]
# }
#
# resource "aws_cloudwatch_metric_alarm" "api_gateway_cpu_low" {
#   alarm_name          = "api-gateway-cpu-low"
#   comparison_operator = "LessThanOrEqualToThreshold"
#   evaluation_periods  = 3
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/ECS"
#   period              = 60
#   statistic           = "Average"
#   threshold           = 30
#
#   dimensions = {
#     ClusterName = aws_ecs_cluster.main.name
#     ServiceName = aws_ecs_service.api_gateway.name
#   }
#
#   alarm_actions = [aws_appautoscaling_policy.api_gateway_scale_in.arn]
# }