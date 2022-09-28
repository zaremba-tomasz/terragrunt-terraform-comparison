require "aws-sdk-ssm"
require "aws-sdk-eventbridge"
require "graphql_helper"

describe "backend stack" do
  before(:all) do
    stack_path = File.expand_path("../..", __dir__)
    ts_root = File.expand_path("../../..", stack_path)
    terraspace.build_test_harness(
      name:    "backend-harness",
      modules: {
        "common-tags": "#{ts_root}/app/modules/common-tags",
        "appsync": "#{ts_root}/vendor/modules/appsync",
        "dynamodb-table": "#{ts_root}/vendor/modules/dynamodb-table",
        "eventbridge": "#{ts_root}/vendor/modules/eventbridge",
        "lambda": "#{ts_root}/vendor/modules/lambda",
      },
      stacks:  {backend: stack_path},
      config:  "#{stack_path}/test/spec/fixtures/config",
      tfvars:  {backend: "#{stack_path}/test/spec/fixtures/tfvars/test.tfvars"},
    )
    # terraspace.up("backend")
  end

  after(:all) do
    # terraspace.down("backend")
  end

  it "should successfully deploy" do
    # register an event that should be stored in DynamoDB
    eventbridge_client = Aws::EventBridge::Client.new(
      region: ENV['AWS_REGION'],
    )

    eventbus_name = terraspace.output("backend", "eventbridge_bus_name")
    eventbridge_client.put_events({
      entries: [{
        time: Time.now,
        source: "app.posts",
        detail_type: "post",
        detail: '{"id":"1"}',
        event_bus_name: eventbus_name,
      }],
    })

    # sleep a while and wait for event to be processed
    pp "Waiting for event processing..."
    sleep(10)

    # fetch API key from SSM
    ssm_client = Aws::SSM::Client.new(
      region: ENV['AWS_REGION'],
    )

    api_key_ssm_parameter_name = terraspace.output("backend", "appsync_api_key_ssm_parameter_name")
    appsync_api_key = ssm_client.get_parameter({
      name: api_key_ssm_parameter_name,
      with_decryption: true,
    }).parameter.value

    # use GraphQL endpoint to check whether event was stored in DynamoDB
    # TODO: fix me because Graphql client initialization is ending up with an error
    # graphql_api_endpoint = terraspace.output("backend", "appsync_graphql_endpoint")
    # graphql_client = GraphqlHelper.new(graphql_api_endpoint, appsync_api_key)
    #
    # query = graphql_client.parse <<-'GRAPHQL'
    #   query ($postID: ID!) { post(id: $postID) { id } }
    # GRAPHQL
  end
end
