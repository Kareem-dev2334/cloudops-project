terraform {
  required_version = ">=1.5.0"
}

locals {
  project_name = "CloudOps"
  environment  = "dev"
}

output "monitoring_status" {
  value = var.enable_monitoring ? "Enabled" : "Disabled"
}


output "project_info" {
  value = "${local.project_name}-${local.environment}"
}

output "selected_region" {
  value = var.aws_region
}
