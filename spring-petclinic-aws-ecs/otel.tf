resource "aws_cloudwatch_log_group" "otel" {
  name              = "/ecs/aws-otel-collector"
  retention_in_days = 1
}

locals {
  otel_config = <<-EOT
    receivers:
      zipkin:
        endpoint: 0.0.0.0:9411
    processors:
      batch/traces:
        timeout: 1s
    exporters:
      awsxray:
        region: ap-northeast-1
    service:
      pipelines:
        traces:
          receivers: [zipkin]
          processors: [batch/traces]
          exporters: [awsxray]
  EOT

  otel_sidecar = {
    name      = "aws-otel-collector"
    image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
    essential = false
    environment = [
      {
        name  = "AOT_CONFIG_CONTENT"
        value = local.otel_config
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/aws-otel-collector"
        awslogs-region        = "ap-northeast-1"
        awslogs-stream-prefix = "ecs"
      }
    }
  }
}