package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDevEnvironment(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir:    "../dev",
		TerraformBinary: "terragrunt",
	})

	defer terraform.TgDestroyAll(t, terraformOptions)
	terraform.TgApplyAll(t, terraformOptions)
}
