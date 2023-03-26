locals {
  route53_health_check = "citi.com"
}

data "aws_lb" "haproxy_us-east-2" {
  count = var.environment == "prod" ? 1 : 0
  tags = {
    "kubernetes.io/service-name" = "default/haproxy"
  }
}

data "aws_lb" "haproxy_us-west-2" {
  count    = var.environment == "prod" ? 1 : 0
  provider = aws.us-west-2
  tags = {
    "kubernetes.io/service-name" = "default/haproxy"
  }
}

resource "aws_sns_topic" "sns_topic" {
  count    = var.environment == "prod" ? 1 : 0
  provider = aws.us-east-1
  name     = "${var.environment}-endpoint-monitoring"
}

resource "aws_sns_topic_subscription" "aws_sns_topic_subscription" {
  for_each  = toset(var.emails)
  provider  = aws.us-east-1
  topic_arn = aws_sns_topic.sns_topic[0].arn
  protocol  = "email"
  endpoint  = each.key
}

resource "aws_cloudwatch_metric_alarm" "citi_us-east-2" {
  count               = var.environment == "prod" ? 1 : 0
  provider            = aws.us-east-1
  alarm_name          = "nlb-us-east-2"
  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = "1"
  evaluation_periods  = "1"
  period              = "60"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
  ok_actions          = [aws_sns_topic.sns_topic[0].arn]
  dimensions = {
    HealthCheckId = aws_route53_health_check.citi_us-east-2[0].id
  }
  alarm_description = "This metric monitors main api health check"
}

resource "aws_route53_health_check" "citi_us-east-2" {
  count             = var.environment == "prod" ? 1 : 0
  fqdn              = data.aws_lb.haproxy_us-east-2[0].dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/actuator/health"
  failure_threshold = "1"
  request_interval  = "10"
  measure_latency   = true
  tags = {
    Name = "nlb-us-east-2"
  }
}


resource "aws_cloudwatch_metric_alarm" "citi_west-2" {
  count               = var.environment == "prod" ? 1 : 0
  provider            = aws.us-east-1
  alarm_name          = "nlb-us-west-2"
  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = "1"
  evaluation_periods  = "1"
  period              = "60"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
  ok_actions          = [aws_sns_topic.sns_topic[0].arn]
  dimensions = {
    HealthCheckId = aws_route53_health_check.citi_west-2[0].id
  }
  alarm_description = "This metric monitors main api health check"
}

resource "aws_route53_health_check" "citi_west-2" {
  count             = var.environment == "prod" ? 1 : 0
  fqdn              = data.aws_lb.haproxy_us-west-2[0].dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/actuator/health"
  failure_threshold = "1"
  request_interval  = "10"
  measure_latency   = true
  tags = {
    Name = "nlb-us-west-2"
  }
}

resource "aws_cloudwatch_metric_alarm" "citi" {
  count               = var.environment == "prod" ? 1 : 0
  provider            = aws.us-east-1
  alarm_name          = "citiintegrator.${local.route53_health_check}"
  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = "1"
  evaluation_periods  = "1"
  period              = "60"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
  ok_actions          = [aws_sns_topic.sns_topic[0].arn]
  dimensions = {
    HealthCheckId = aws_route53_health_check.citi_ga[0].id
  }
  alarm_description = "This metric monitors main api health check"
}

resource "aws_route53_health_check" "citi_ga" {
  count             = var.environment == "prod" ? 1 : 0
  fqdn              = "citiintegrator.${local.route53_health_check}"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/actuator/health"
  failure_threshold = "1"
  request_interval  = "10"
  measure_latency   = true
  tags = {
    Name = "citiintegrator.${local.route53_health_check}"
  }
}

resource "aws_route53_health_check" "calculated" {
  count                  = var.environment == "prod" ? 1 : 0
  type                   = "CALCULATED"
  child_health_threshold = 1
  child_healthchecks     = [aws_route53_health_check.citi_ga[0].id, aws_route53_health_check.citi_us-east-2[0].id, aws_route53_health_check.citi_west-2[0].id]
  tags = {
    Name = "calculated"
  }
}

resource "aws_cloudwatch_metric_alarm" "calculated" {
  count               = var.environment == "prod" ? 1 : 0
  provider            = aws.us-east-1
  alarm_name          = "calculated"
  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = "1"
  evaluation_periods  = "1"
  period              = "60"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.sns_topic[0].arn]
  ok_actions          = [aws_sns_topic.sns_topic[0].arn]
  dimensions = {
    HealthCheckId = aws_route53_health_check.calculated[0].id
  }
  alarm_description = "This metric monitors calculated health check"
}
