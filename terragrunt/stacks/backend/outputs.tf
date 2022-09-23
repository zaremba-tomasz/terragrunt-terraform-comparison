output "eventbridge_bus_name" {
  value       = module.event_bridge.eventbridge_bus_name
  description = "The name of the created EventBridge bus"
}

output "appsync_graphql_endpoint" {
  value       = module.appsync.appsync_graphql_api_uris[0]["GRAPHQL"]
  description = "The URI of the created AppSync GraphQL API"
}

output "appsync_api_key_ssm_parameter_name" {
  value       = aws_ssm_parameter.appsync_api_key.name
  description = "The name of the SSM parameter where AppSync API key is stored"
}
