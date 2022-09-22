include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${get_terragrunt_dir()}/../../_env/backend.hcl"
  expose = true
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment_name = local.environment_vars.locals.environment
}

inputs = {
  environment = local.environment_name
}
