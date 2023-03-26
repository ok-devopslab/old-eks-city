output "ga-dns" {
  value = var.environment == "prod" ? aws_globalaccelerator_accelerator.aws_globalaccelerator_accelerator[0].dns_name : null
}
