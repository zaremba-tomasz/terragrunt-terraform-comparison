locals {
  tags = {
    Environment  = var.environment
    ManagedBy    = "terraform"
    Stack        = var.stack
    Project      = var.project
    Organisation = var.organisation
  }
}
