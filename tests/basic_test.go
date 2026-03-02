package tests

import (
	"testing"
)

func TestBasicExample(t *testing.T) {
	testWAFv2RuleGroup(t, "basic")
}
