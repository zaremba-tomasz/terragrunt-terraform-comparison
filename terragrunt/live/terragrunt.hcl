remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform_locks"
  }
}

terraform {
  after_hook "Infracost analysis" {
    commands     = ["plan"]
    execute      = [
      "${get_repo_root()}/${get_path_from_repo_root()}/${path_relative_from_include()}/_scripts/analyze-costs.sh",
      "${get_repo_root()}/${get_path_from_repo_root()}"
    ]
    run_on_error = false
  }
}
