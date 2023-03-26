resource "aws_guardduty_detector" "primary" {
  count  = var.environment == "prod-dr" ? 0 : 1
  enable = true
  datasources {
    s3_logs {
      enable = true
    }
  }
}
