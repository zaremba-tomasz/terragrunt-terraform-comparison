locals {
  tags = {
    Environment  = var.environment
    ManagedBy    = "terraform"
    Stack        = var.stack_name
    Project      = var.project_name
    Organisation = var.organisation
  }
}
