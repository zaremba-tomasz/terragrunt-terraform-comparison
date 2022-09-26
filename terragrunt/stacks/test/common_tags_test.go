package test

import (
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestCommonTagsStack(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../common-tags",
		Vars: map[string]interface{}{
			"environment":  "test",
			"project_name": "test-project-name",
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	outputTags := terraform.OutputMap(t, terraformOptions, "tags")
	expectedTags := map[string]string{
		"Environment":  "test",
		"ManagedBy":    "terraform",
		"Organisation": "NearForm",
		"Project":      "test-project-name",
	}
	assert.Equal(t, expectedTags, outputTags)
}
