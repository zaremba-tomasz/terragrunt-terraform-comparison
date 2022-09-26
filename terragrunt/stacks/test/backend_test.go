package test

import (
	"context"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/eventbridge"
	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	graphql "github.com/hasura/go-graphql-client"
	"github.com/stretchr/testify/assert"
)

func TestBackendStack(t *testing.T) {
	awsRegion := os.Getenv("AWS_REGION")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../backend",
		Vars: map[string]interface{}{
			"environment": "test",
			"tags": map[string]string{
				"ManagedBy": "TerragruntTest",
			},
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	sess, _ := session.NewSession()
	eventBridgeSvc := eventbridge.New(sess)

	outputEventBridgeEndpointId := terraform.Output(t, terraformOptions, "eventbridge_bus_name")
	outputAppSyncEndpoint := terraform.Output(t, terraformOptions, "appsync_graphql_endpoint")
	outputAppSyncApiKeySsmParameterName := terraform.Output(t, terraformOptions, "appsync_api_key_ssm_parameter_name")

	// register an event that should be stored in DynamoDB
	eventEntryDetail := "{\"id\":\"1\"}"
	eventEntryDetailType := "post"
	eventEntrySource := "app.posts"
	eventEntryTime := time.Now()
	eventEntry := eventbridge.PutEventsRequestEntry{
		Detail:       &eventEntryDetail,
		DetailType:   &eventEntryDetailType,
		EventBusName: &outputEventBridgeEndpointId,
		Source:       &eventEntrySource,
		Time:         &eventEntryTime,
	}

	putEventsInput := eventbridge.PutEventsInput{
		Entries: []*eventbridge.PutEventsRequestEntry{&eventEntry},
	}

	_, putEventsErr := eventBridgeSvc.PutEvents(&putEventsInput)

	if putEventsErr != nil {
		t.Log(putEventsErr)
		t.Fail()
	}

	// sleep a while and wait for event to be processed
	t.Log("Waiting for event processing...")
	time.Sleep(10 * time.Second)

	// fetch API key from SSM
	appsyncApiKey := aws.GetParameter(t, awsRegion, outputAppSyncApiKeySsmParameterName)

	// use GraphQL endpoint to check whether event was stored in DynamoDB
	client := graphql.NewClient(outputAppSyncEndpoint, &http.Client{}).WithRequestModifier(func(r *http.Request) {
		r.Header.Add("x-api-key", appsyncApiKey)
	})

	query := `query ($postID: ID!) { post(id: $postID) { id } }`
	variables := map[string]interface{}{
		"postID": graphql.ID("1"),
	}

	rawResponse, queryError := client.ExecRaw(context.Background(), query, variables)
	if queryError != nil {
		t.Log(queryError)
		t.Fail()
	} else {
		assert.Equal(t, `{"post":{"id":"1"}}`, string(rawResponse))
	}
}
