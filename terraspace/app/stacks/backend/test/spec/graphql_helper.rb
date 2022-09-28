require "graphql/client"
require "graphql/client/http"

class GraphqlHelper

  attr_reader :api_key
  attr_reader :graphql_client

  def initialize(uri, api_key)
    @api_key = api_key

    http_adapter = GraphQL::Client::HTTP.new(uri) do
      def headers(context)
        {
          "Content-Type": "application/json",
          "x-api-key": @api_key,
        }
      end
    end
    schema = GraphQL::Client.load_schema("./resources/schema.json")

    @graphql_client = GraphQL::Client.new(schema: schema, execute: http_adapter)
  end

  def graphql_client
    @graphql_client
  end
end