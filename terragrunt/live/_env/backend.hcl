locals {
  source_base_url = "${path_relative_from_include()}/../..//stacks//backend" # in real project this should be fetched from separated Git repository
}

terraform {
  source = local.source_base_url
}
