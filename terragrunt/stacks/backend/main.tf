locals {
  stack_name                = "backend"
  resources_name_prefix     = "${var.environment}-${local.stack_name}"
  posts_dynamodb_table_name = "${local.resources_name_prefix}-posts" // this one is needed because of appsync modules issues with dynamic binding
  tags = merge({
    Stack = "backend"
  }, var.tags)
}

data "aws_region" "current" {}

module "posts_dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "3.1.1"

  name         = local.posts_dynamodb_table_name
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"
  tags         = local.tags

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]
}

module "store_post_lambda_package" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_function = false
  create_package  = true
  runtime         = "nodejs14.x"
  source_path     = "${path.module}/resources/lambda/store-post"
  tags            = local.tags
}

module "store_post_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.0.2"

  create_function          = true
  create_package           = false
  publish                  = true
  local_existing_package   = module.store_post_lambda_package.local_filename
  function_name            = "${local.resources_name_prefix}-store-post"
  handler                  = "index.handler"
  runtime                  = "nodejs14.x"
  attach_policy_statements = true
  tags                     = local.tags

  allowed_triggers = {
    EventBridgeRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.event_bridge.eventbridge_rule_arns["StorePosts"]
    }
  }

  policy_statements = {
    PostsDynamoDBTableAccess = {
      effect    = "Allow",
      actions   = ["dynamodb:PutItem"],
      resources = [module.posts_dynamodb_table.dynamodb_table_arn]
    }
  }

  environment_variables = {
    DYNAMODB_TABLE_NAME = local.posts_dynamodb_table_name
  }

  depends_on = [module.store_post_lambda_package]
}

module "event_bridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "1.15.0"

  bus_name             = "${local.resources_name_prefix}-bus"
  attach_lambda_policy = true
  lambda_target_arns   = [module.store_post_lambda.lambda_function_arn]
  tags                 = local.tags

  rules = {
    StorePosts = {
      description   = "Capture all posts data"
      event_pattern = jsonencode({ "source" : ["app.posts"] })
      enabled       = true
    }
  }

  targets = {
    StorePosts = [
      {
        name = module.store_post_lambda.lambda_function_name
        arn  = module.store_post_lambda.lambda_function_arn
      }
    ]
  }
}

module "appsync" {
  source  = "terraform-aws-modules/appsync/aws"
  version = "1.5.2"

  name   = "${local.resources_name_prefix}-api"
  schema = file("${path.module}/resources/appsync/schema/schema.graphql")
  tags   = local.tags

  api_keys = {
    default = null
  }

  datasources = {
    DynamoDB = {
      type       = "AMAZON_DYNAMODB"
      table_name = local.posts_dynamodb_table_name
      region     = data.aws_region.current.name
    }
  }

  resolvers = {
    "Query.post" = {
      data_source       = "DynamoDB"
      request_template  = file("${path.module}/resources/appsync/mapping-templates/query-single-post-request-template.json")
      response_template = "$util.toJson($context.result)"
    }
  }
}

resource "aws_ssm_parameter" "appsync_api_key" {
  name        = "/${var.environment}/${local.stack_name}/appsync/api_key"
  description = "The API key required to authorize against AppSync API"
  type        = "SecureString"
  value       = module.appsync.appsync_api_key_key["default"]
  tags        = local.tags
}
