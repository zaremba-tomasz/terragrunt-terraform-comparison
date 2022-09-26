module "common_tags" {
  source = "../../modules/common-tags"

  environment  = var.environment
  project_name = var.project_name
}
