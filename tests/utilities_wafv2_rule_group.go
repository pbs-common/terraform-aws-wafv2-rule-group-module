package tests

import (
	"fmt"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func testWAFv2RuleGroup(t *testing.T, variant string) {
	t.Parallel()

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify that a rule group ARN was created with the expected WAFv2 ARN prefix
	ruleGroupARN := terraform.Output(t, terraformOptions, "rule_group_arn")
	assert.NotEmpty(t, ruleGroupARN, "rule_group_arn output must not be empty")
	assert.True(
		t,
		strings.HasPrefix(ruleGroupARN, "arn:aws:wafv2:"),
		"rule_group_arn must begin with arn:aws:wafv2:, got: %s", ruleGroupARN,
	)
	assert.Contains(t, ruleGroupARN, "rulegroup", "rule_group_arn must contain 'rulegroup'")

	// Verify IP set ARNs are populated
	ipSetARNsRaw := terraform.OutputMap(t, terraformOptions, "ip_set_arns")
	assert.Contains(t, ipSetARNsRaw, "blacklist", "ip_set_arns must contain key 'blacklist'")
	assert.Contains(t, ipSetARNsRaw, "allowlist", "ip_set_arns must contain key 'allowlist'")

	for key, arn := range ipSetARNsRaw {
		assert.True(
			t,
			strings.HasPrefix(arn, "arn:aws:wafv2:"),
			"ip_set_arns[%s] must begin with arn:aws:wafv2:, got: %s", key, arn,
		)
	}
}
