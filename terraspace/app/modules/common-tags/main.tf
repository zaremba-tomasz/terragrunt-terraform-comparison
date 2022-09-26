locals {
  tags = {
    Environment  = var.environment
    ManagedBy    = "terraform"
    Project      = var.project_name
    Organisation = var.organisation
  }
}
