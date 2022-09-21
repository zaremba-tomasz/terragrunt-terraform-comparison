locals {
  stack_name                = "backend"
  resources_name_prefix     = "${var.environment}-${local.stack_name}"
  posts_dynamodb_table_name = "${local.resources_name_prefix}-posts" // this one is needed because of appsync modules issues with dynamic binding
}

data "aws_region" "current" {}

module "common_tags" {
  source = "../../modules/common-tags"

  environment  = var.environment
  project_name = var.project_name
  stack_name   = local.stack_name
}

module "posts_dynamodb_table" {
  source = "../../modules/dynamodb-table"

  name         = local.posts_dynamodb_table_name
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"
  tags         = module.common_tags.tags

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]
}

module "store_post_lambda_package" {
  source = "../../modules/lambda"

  create_function = false
  create_package  = true
  runtime         = "nodejs14.x"
  source_path     = "${path.module}/resources/lambda/store-post"
  tags            = module.common_tags.tags
}

module "store_post_lambda" {
  source = "../../modules/lambda"

  create_function          = true
  create_package           = false
  publish                  = true
  local_existing_package   = module.store_post_lambda_package.local_filename
  function_name            = "${local.resources_name_prefix}-store-post"
  handler                  = "index.handler"
  runtime                  = "nodejs14.x"
  attach_policy_statements = true
  tags                     = module.common_tags.tags

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
  source = "../../modules/eventbridge"

  bus_name             = "${local.resources_name_prefix}-bus"
  attach_lambda_policy = true
  lambda_target_arns   = [module.store_post_lambda.lambda_function_arn]
  tags                 = module.common_tags.tags

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
  source = "../../modules/appsync"

  name   = "${local.resources_name_prefix}-api"
  schema = file("${path.module}/resources/appsync/schema/schema.graphql")
  tags   = module.common_tags.tags

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
    "Query.singlePost" = {
      data_source       = "DynamoDB"
      request_template  = file("${path.module}/resources/appsync/mapping-templates/query-single-post-request-template.json")
      response_template = "$util.toJson($context.result)"
    }
  }
}