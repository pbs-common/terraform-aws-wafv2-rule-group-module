# Plan-only tests for the rule shapes of var.rules. No AWS calls: the provider is mocked.
# Each assertion wraps its path in try() so a missing block fails with its own error_message.
# Every run has its own state_key and runs in parallel, so one run's error skips no other run.

test {
  parallel = true
}

mock_provider "aws" {
  override_during = plan

  override_data {
    target = data.aws_default_tags.common_tags
    values = { tags = {} }
  }

  mock_resource "aws_wafv2_ip_set" {
    defaults = { arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/test/00000000-0000-0000-0000-000000000000" }
  }

  mock_resource "aws_wafv2_rule_group" {
    defaults = { arn = "arn:aws:wafv2:us-east-1:123456789012:regional/rulegroup/test/00000000-0000-0000-0000-000000000000" }
  }

  mock_resource "aws_wafv2_regex_pattern_set" {
    defaults = { arn = "arn:aws:wafv2:us-east-1:123456789012:regional/regexpatternset/test/00000000-0000-0000-0000-000000000000" }
  }
}

variables {
  organization = "pbs"
  environment  = "dev"
  product      = "waf-test"
  owner        = "cloud-ops"
  repo         = "https://github.com/pbs-common/terraform-aws-wafv2-rule-group-module.git"
}

run "not_regex_match_renders_not_statement" {
  command   = plan
  state_key = "not_regex_match_renders_not_statement"

  variables {
    rules = [{
      name     = "block-non-allowed-methods"
      priority = 0
      action   = "block"
      not_regex_match = {
        regex_string   = "^(GET|HEAD)$"
        field_to_match = { type = "method" }
      }
    }]
  }

  assert {
    condition     = try(one(aws_wafv2_rule_group.this.rule).statement[0].not_statement[0].statement[0].regex_match_statement[0].regex_string, null) == "^(GET|HEAD)$"
    error_message = "not_regex_match must render statement.not_statement.statement.regex_match_statement with the given regex_string."
  }

  assert {
    condition     = try(length(one(aws_wafv2_rule_group.this.rule).statement[0].not_statement[0].statement[0].regex_match_statement[0].field_to_match[0].method), 0) == 1
    error_message = "not_regex_match must render field_to_match.method for field_to_match.type method."
  }

  assert {
    condition     = try([for t in one(aws_wafv2_rule_group.this.rule).statement[0].not_statement[0].statement[0].regex_match_statement[0].text_transformation : { priority = t.priority, type = t.type }], null) == [{ priority = 0, type = "NONE" }]
    error_message = "not_regex_match must default text_transformation to priority 0 type NONE, as regex_match does."
  }
}

run "challenge_action_renders" {
  command   = plan
  state_key = "challenge_action_renders"

  variables {
    rules = [{
      name      = "challenge-high-risk-countries"
      priority  = 0
      action    = "challenge"
      geo_match = { country_codes = ["KP"] }
    }]
  }

  assert {
    condition     = try(length(one(aws_wafv2_rule_group.this.rule).action[0].challenge), 0) == 1 && try(length(one(aws_wafv2_rule_group.this.rule).action[0].block), 1) == 0
    error_message = "action challenge must render action.challenge and no other action."
  }
}

run "captcha_action_renders" {
  command   = plan
  state_key = "captcha_action_renders"

  variables {
    rules = [{
      name      = "captcha-high-risk-countries"
      priority  = 0
      action    = "captcha"
      geo_match = { country_codes = ["KP"] }
    }]
  }

  assert {
    condition     = try(length(one(aws_wafv2_rule_group.this.rule).action[0].captcha), 0) == 1 && try(length(one(aws_wafv2_rule_group.this.rule).action[0].block), 1) == 0
    error_message = "action captcha must render action.captcha and no other action."
  }
}

run "and_statements_render_in_order" {
  command   = plan
  state_key = "and_statements_render_in_order"

  variables {
    rules = [{
      name     = "block-login-scripted-clients"
      priority = 0
      action   = "block"
      and_statements = [
        {
          byte_match = {
            search_string         = "/login"
            positional_constraint = "STARTS_WITH"
            field_to_match        = { type = "uri_path" }
          }
        },
        {
          regex_match = {
            regex_string   = "(?i)(curl|wget)"
            field_to_match = { type = "single_header", name = "user-agent" }
          }
        },
      ]
    }]
  }

  assert {
    condition     = try(length(one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement), 0) == 2
    error_message = "and_statements must render one and_statement with one statement per element."
  }

  assert {
    condition = try(
      one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[0].byte_match_statement[0].search_string == "/login" &&
      length(one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[0].byte_match_statement[0].field_to_match[0].uri_path) == 1,
      false
    )
    error_message = "and_statements[0].byte_match must render as the first and_statement statement on uri_path."
  }

  assert {
    condition = try(
      one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[1].regex_match_statement[0].regex_string == "(?i)(curl|wget)" &&
      one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[1].regex_match_statement[0].field_to_match[0].single_header[0].name == "user-agent",
      false
    )
    error_message = "and_statements[1].regex_match must render as the second and_statement statement on single_header user-agent."
  }

  assert {
    condition = try(
      [for t in one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[0].byte_match_statement[0].text_transformation : { priority = t.priority, type = t.type }] == [{ priority = 0, type = "NONE" }] &&
      [for t in one(aws_wafv2_rule_group.this.rule).statement[0].and_statement[0].statement[1].regex_match_statement[0].text_transformation : { priority = t.priority, type = t.type }] == [{ priority = 0, type = "NONE" }],
      false
    )
    error_message = "and_statements sub-statements must default text_transformation to priority 0 type NONE, as byte_match and regex_match do."
  }
}

run "control_regex_match_unchanged" {
  command   = plan
  state_key = "control_regex_match_unchanged"

  variables {
    rules = [{
      name     = "block-path-traversal"
      priority = 0
      action   = "block"
      regex_match = {
        regex_string         = "(\\.\\./)"
        field_to_match       = { type = "query_string" }
        text_transformations = [{ priority = 1, type = "URL_DECODE" }]
      }
    }]
  }

  assert {
    condition = try(
      one(aws_wafv2_rule_group.this.rule).statement[0].regex_match_statement[0].regex_string == "(\\.\\./)" &&
      length(one(aws_wafv2_rule_group.this.rule).statement[0].regex_match_statement[0].field_to_match[0].query_string) == 1 &&
      [for t in one(aws_wafv2_rule_group.this.rule).statement[0].regex_match_statement[0].text_transformation : { priority = t.priority, type = t.type }] == [{ priority = 1, type = "URL_DECODE" }] &&
      length(one(aws_wafv2_rule_group.this.rule).statement[0].not_statement) == 0 &&
      length(one(aws_wafv2_rule_group.this.rule).statement[0].and_statement) == 0 &&
      length(one(aws_wafv2_rule_group.this.rule).action[0].block) == 1,
      false
    )
    error_message = "An existing regex_match rule must still render unchanged."
  }
}

run "accepts_every_statement_type" {
  command   = plan
  state_key = "accepts_every_statement_type"

  variables {
    ip_sets            = { deny = { description = "deny", addresses = ["192.0.2.1/32"] } }
    regex_pattern_sets = { bots = { description = "bots", regular_expressions = ["(?i)badbot"] } }
    rules = [
      { name = "ip", priority = 0, action = "block", ip_set_ref = { key = "deny" } },
      { name = "byte", priority = 1, action = "allow", byte_match = { search_string = "/health", positional_constraint = "STARTS_WITH", field_to_match = { type = "uri_path" } } },
      { name = "geo", priority = 2, action = "block", geo_match = { country_codes = ["KP"] } },
      { name = "regex", priority = 3, action = "block", regex_match = { regex_string = "x", field_to_match = { type = "uri_path" } } },
      { name = "regex-set", priority = 4, action = "count", regex_set_ref = { key = "bots", field_to_match = { type = "single_header", name = "user-agent" } } },
      { name = "rate", priority = 5, action = "block", rate_based = { limit = 1000 } },
      { name = "or", priority = 6, action = "allow", or_statements = [{ ip_set_ref_key = "deny" }, { byte_match = { search_string = "t", positional_constraint = "EXACTLY", field_to_match = { type = "single_header", name = "x-t" } } }] },
      { name = "and-not-regex-geo", priority = 7, action = "block", and_not_regex_geo = { regex_string = "^/exempt", field_to_match = { type = "uri_path" }, country_codes = ["RU"] } },
      { name = "not-regex", priority = 8, action = "block", not_regex_match = { regex_string = "^GET$", field_to_match = { type = "method" } } },
      { name = "and", priority = 9, action = "block", and_statements = [{ byte_match = { search_string = "/a", positional_constraint = "STARTS_WITH", field_to_match = { type = "uri_path" } } }, { regex_match = { regex_string = "b", field_to_match = { type = "query_string" } } }] },
    ]
  }

  assert {
    condition     = length(aws_wafv2_rule_group.this.rule) == 10
    error_message = "Every supported statement type must pass the one-statement validation and render one rule."
  }
}

run "refuse_rule_without_statement" {
  command   = plan
  state_key = "refuse_rule_without_statement"

  variables {
    rules = [{ name = "empty", priority = 0, action = "block" }]
  }

  expect_failures = [var.rules]
}

run "refuse_rule_with_two_statements" {
  command   = plan
  state_key = "refuse_rule_with_two_statements"

  variables {
    rules = [{
      name        = "two"
      priority    = 0
      action      = "block"
      geo_match   = { country_codes = ["KP"] }
      regex_match = { regex_string = "x", field_to_match = { type = "uri_path" } }
    }]
  }

  expect_failures = [var.rules]
}

run "refuse_and_statements_of_one" {
  command   = plan
  state_key = "refuse_and_statements_of_one"

  variables {
    rules = [{
      name           = "and-of-one"
      priority       = 0
      action         = "block"
      and_statements = [{ byte_match = { search_string = "/a", positional_constraint = "STARTS_WITH", field_to_match = { type = "uri_path" } } }]
    }]
  }

  expect_failures = [var.rules]
}

run "refuse_and_statements_element_with_both" {
  command   = plan
  state_key = "refuse_and_statements_element_with_both"

  variables {
    rules = [{
      name     = "and-element-both"
      priority = 0
      action   = "block"
      and_statements = [
        {
          byte_match  = { search_string = "/a", positional_constraint = "STARTS_WITH", field_to_match = { type = "uri_path" } }
          regex_match = { regex_string = "b", field_to_match = { type = "query_string" } }
        },
        { regex_match = { regex_string = "c", field_to_match = { type = "query_string" } } },
      ]
    }]
  }

  expect_failures = [var.rules]
}

run "refuse_and_statements_element_with_neither" {
  command   = plan
  state_key = "refuse_and_statements_element_with_neither"

  variables {
    rules = [{
      name     = "and-element-neither"
      priority = 0
      action   = "block"
      and_statements = [
        {},
        { regex_match = { regex_string = "c", field_to_match = { type = "query_string" } } },
      ]
    }]
  }

  expect_failures = [var.rules]
}

run "basic_example_plans" {
  command   = plan
  state_key = "basic_example_plans"

  module {
    source = "./examples/basic"
  }

  assert {
    condition     = startswith(output.rule_group_arn, "arn:aws:wafv2:")
    error_message = "examples/basic must pass the one-statement validation and plan."
  }
}
