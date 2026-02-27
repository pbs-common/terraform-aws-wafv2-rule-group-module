# ─── IP sets ──────────────────────────────────────────────────────────────────

resource "aws_wafv2_ip_set" "this" {
  for_each = var.ip_sets

  name               = "${local.name}-${each.key}"
  description        = each.value.description
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = local.tags
}

# ─── Regex pattern sets ───────────────────────────────────────────────────────

resource "aws_wafv2_regex_pattern_set" "this" {
  for_each = var.regex_pattern_sets

  name        = "${local.name}-${each.key}"
  description = each.value.description
  scope       = var.scope

  dynamic "regular_expression" {
    for_each = each.value.regular_expressions
    content {
      regex_string = regular_expression.value
    }
  }

  tags = local.tags
}

# ─── Rule group ───────────────────────────────────────────────────────────────

resource "aws_wafv2_rule_group" "this" {
  name        = "${local.name}-rule-group"
  description = "Custom WAF rules - ${local.name}"
  scope       = var.scope
  capacity    = var.capacity

  dynamic "rule" {
    for_each = { for r in var.rules : r.name => r }

    content {
      name     = rule.value.name
      priority = rule.value.priority

      statement {

        # ip_set_ref ──────────────────────────────────────────────────────────
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.ip_set_ref != null ? [rule.value.ip_set_ref] : []
          content {
            arn = local.ip_set_arns[ip_set_reference_statement.value.key]
          }
        }

        # byte_match ──────────────────────────────────────────────────────────
        dynamic "byte_match_statement" {
          for_each = rule.value.byte_match != null ? [rule.value.byte_match] : []
          content {
            search_string         = byte_match_statement.value.search_string
            positional_constraint = byte_match_statement.value.positional_constraint

            field_to_match {
              dynamic "uri_path" {
                for_each = byte_match_statement.value.field_to_match.type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = byte_match_statement.value.field_to_match.type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = byte_match_statement.value.field_to_match.type == "body" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = byte_match_statement.value.field_to_match.type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = byte_match_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = byte_match_statement.value.field_to_match.type == "single_header" ? [1] : []
                content {
                  name = byte_match_statement.value.field_to_match.name
                }
              }
              dynamic "single_query_argument" {
                for_each = byte_match_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                content {
                  name = byte_match_statement.value.field_to_match.name
                }
              }
            }

            dynamic "text_transformation" {
              for_each = byte_match_statement.value.text_transformations != null ? byte_match_statement.value.text_transformations : local.default_ttx
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }

        # geo_match ───────────────────────────────────────────────────────────
        dynamic "geo_match_statement" {
          for_each = rule.value.geo_match != null ? [rule.value.geo_match] : []
          content {
            country_codes = geo_match_statement.value.country_codes
          }
        }

        # regex_match ─────────────────────────────────────────────────────────
        dynamic "regex_match_statement" {
          for_each = rule.value.regex_match != null ? [rule.value.regex_match] : []
          content {
            regex_string = regex_match_statement.value.regex_string

            field_to_match {
              dynamic "uri_path" {
                for_each = regex_match_statement.value.field_to_match.type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = regex_match_statement.value.field_to_match.type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = regex_match_statement.value.field_to_match.type == "body" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = regex_match_statement.value.field_to_match.type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = regex_match_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = regex_match_statement.value.field_to_match.type == "single_header" ? [1] : []
                content {
                  name = regex_match_statement.value.field_to_match.name
                }
              }
              dynamic "single_query_argument" {
                for_each = regex_match_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                content {
                  name = regex_match_statement.value.field_to_match.name
                }
              }
            }

            dynamic "text_transformation" {
              for_each = regex_match_statement.value.text_transformations != null ? regex_match_statement.value.text_transformations : local.default_ttx
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }

        # regex_set_ref ───────────────────────────────────────────────────────
        dynamic "regex_pattern_set_reference_statement" {
          for_each = rule.value.regex_set_ref != null ? [rule.value.regex_set_ref] : []
          content {
            arn = local.regex_pattern_set_arns[regex_pattern_set_reference_statement.value.key]

            field_to_match {
              dynamic "uri_path" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "uri_path" ? [1] : []
                content {}
              }
              dynamic "method" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "method" ? [1] : []
                content {}
              }
              dynamic "body" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "body" ? [1] : []
                content {}
              }
              dynamic "query_string" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "query_string" ? [1] : []
                content {}
              }
              dynamic "all_query_arguments" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                content {}
              }
              dynamic "single_header" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "single_header" ? [1] : []
                content {
                  name = regex_pattern_set_reference_statement.value.field_to_match.name
                }
              }
              dynamic "single_query_argument" {
                for_each = regex_pattern_set_reference_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                content {
                  name = regex_pattern_set_reference_statement.value.field_to_match.name
                }
              }
            }

            dynamic "text_transformation" {
              for_each = regex_pattern_set_reference_statement.value.text_transformations != null ? regex_pattern_set_reference_statement.value.text_transformations : local.default_ttx
              content {
                priority = text_transformation.value.priority
                type     = text_transformation.value.type
              }
            }
          }
        }

        # rate_based ──────────────────────────────────────────────────────────
        dynamic "rate_based_statement" {
          for_each = rule.value.rate_based != null ? [rule.value.rate_based] : []
          content {
            limit                 = rate_based_statement.value.limit
            evaluation_window_sec = rate_based_statement.value.evaluation_window_sec
            aggregate_key_type    = rate_based_statement.value.aggregate_key_type

            dynamic "forwarded_ip_config" {
              for_each = rate_based_statement.value.forwarded_ip_config != null ? [rate_based_statement.value.forwarded_ip_config] : []
              content {
                header_name       = forwarded_ip_config.value.header_name
                fallback_behavior = forwarded_ip_config.value.fallback_behavior
              }
            }

            dynamic "scope_down_statement" {
              for_each = rate_based_statement.value.scope_down != null ? [rate_based_statement.value.scope_down] : []
              content {

                dynamic "ip_set_reference_statement" {
                  for_each = scope_down_statement.value.ip_set_ref_key != null ? [scope_down_statement.value.ip_set_ref_key] : []
                  content {
                    arn = local.ip_set_arns[ip_set_reference_statement.value]
                  }
                }

                dynamic "geo_match_statement" {
                  for_each = scope_down_statement.value.geo_country_codes != null ? [scope_down_statement.value.geo_country_codes] : []
                  content {
                    country_codes = geo_match_statement.value
                  }
                }

                dynamic "not_statement" {
                  for_each = scope_down_statement.value.not_geo_country_codes != null ? [scope_down_statement.value.not_geo_country_codes] : []
                  content {
                    statement {
                      geo_match_statement {
                        country_codes = not_statement.value
                      }
                    }
                  }
                }

                dynamic "byte_match_statement" {
                  for_each = scope_down_statement.value.byte_match != null ? [scope_down_statement.value.byte_match] : []
                  content {
                    search_string         = byte_match_statement.value.search_string
                    positional_constraint = byte_match_statement.value.positional_constraint

                    field_to_match {
                      dynamic "uri_path" {
                        for_each = byte_match_statement.value.field_to_match.type == "uri_path" ? [1] : []
                        content {}
                      }
                      dynamic "method" {
                        for_each = byte_match_statement.value.field_to_match.type == "method" ? [1] : []
                        content {}
                      }
                      dynamic "body" {
                        for_each = byte_match_statement.value.field_to_match.type == "body" ? [1] : []
                        content {}
                      }
                      dynamic "query_string" {
                        for_each = byte_match_statement.value.field_to_match.type == "query_string" ? [1] : []
                        content {}
                      }
                      dynamic "all_query_arguments" {
                        for_each = byte_match_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = byte_match_statement.value.field_to_match.type == "single_header" ? [1] : []
                        content {
                          name = byte_match_statement.value.field_to_match.name
                        }
                      }
                      dynamic "single_query_argument" {
                        for_each = byte_match_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                        content {
                          name = byte_match_statement.value.field_to_match.name
                        }
                      }
                    }

                    dynamic "text_transformation" {
                      for_each = byte_match_statement.value.text_transformations != null ? byte_match_statement.value.text_transformations : local.default_ttx
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }

              }
            }

          }
        }

        # or_statements ───────────────────────────────────────────────────────
        dynamic "or_statement" {
          for_each = rule.value.or_statements != null ? [rule.value.or_statements] : []
          content {
            dynamic "statement" {
              for_each = or_statement.value
              content {

                dynamic "ip_set_reference_statement" {
                  for_each = statement.value.ip_set_ref_key != null ? [statement.value.ip_set_ref_key] : []
                  content {
                    arn = local.ip_set_arns[ip_set_reference_statement.value]
                  }
                }

                dynamic "byte_match_statement" {
                  for_each = statement.value.byte_match != null ? [statement.value.byte_match] : []
                  content {
                    search_string         = byte_match_statement.value.search_string
                    positional_constraint = byte_match_statement.value.positional_constraint

                    field_to_match {
                      dynamic "uri_path" {
                        for_each = byte_match_statement.value.field_to_match.type == "uri_path" ? [1] : []
                        content {}
                      }
                      dynamic "method" {
                        for_each = byte_match_statement.value.field_to_match.type == "method" ? [1] : []
                        content {}
                      }
                      dynamic "body" {
                        for_each = byte_match_statement.value.field_to_match.type == "body" ? [1] : []
                        content {}
                      }
                      dynamic "query_string" {
                        for_each = byte_match_statement.value.field_to_match.type == "query_string" ? [1] : []
                        content {}
                      }
                      dynamic "all_query_arguments" {
                        for_each = byte_match_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = byte_match_statement.value.field_to_match.type == "single_header" ? [1] : []
                        content {
                          name = byte_match_statement.value.field_to_match.name
                        }
                      }
                      dynamic "single_query_argument" {
                        for_each = byte_match_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                        content {
                          name = byte_match_statement.value.field_to_match.name
                        }
                      }
                    }

                    dynamic "text_transformation" {
                      for_each = byte_match_statement.value.text_transformations != null ? byte_match_statement.value.text_transformations : local.default_ttx
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }

              }
            }
          }
        }

        # and_not_regex_geo ───────────────────────────────────────────────────
        dynamic "and_statement" {
          for_each = rule.value.and_not_regex_geo != null ? [rule.value.and_not_regex_geo] : []
          content {
            statement {
              not_statement {
                statement {
                  regex_match_statement {
                    regex_string = and_statement.value.regex_string

                    field_to_match {
                      dynamic "uri_path" {
                        for_each = and_statement.value.field_to_match.type == "uri_path" ? [1] : []
                        content {}
                      }
                      dynamic "method" {
                        for_each = and_statement.value.field_to_match.type == "method" ? [1] : []
                        content {}
                      }
                      dynamic "body" {
                        for_each = and_statement.value.field_to_match.type == "body" ? [1] : []
                        content {}
                      }
                      dynamic "query_string" {
                        for_each = and_statement.value.field_to_match.type == "query_string" ? [1] : []
                        content {}
                      }
                      dynamic "all_query_arguments" {
                        for_each = and_statement.value.field_to_match.type == "all_query_arguments" ? [1] : []
                        content {}
                      }
                      dynamic "single_header" {
                        for_each = and_statement.value.field_to_match.type == "single_header" ? [1] : []
                        content {
                          name = and_statement.value.field_to_match.name
                        }
                      }
                      dynamic "single_query_argument" {
                        for_each = and_statement.value.field_to_match.type == "single_query_argument" ? [1] : []
                        content {
                          name = and_statement.value.field_to_match.name
                        }
                      }
                    }

                    dynamic "text_transformation" {
                      for_each = and_statement.value.text_transformations != null ? and_statement.value.text_transformations : local.default_ttx
                      content {
                        priority = text_transformation.value.priority
                        type     = text_transformation.value.type
                      }
                    }
                  }
                }
              }
            }
            statement {
              geo_match_statement {
                country_codes = and_statement.value.country_codes
              }
            }
          }
        }

      }

      # ── Action ─────────────────────────────────────────────────────────────
      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      # ── Visibility config ──────────────────────────────────────────────────
      visibility_config {
        cloudwatch_metrics_enabled = try(rule.value.visibility_config.cloudwatch_metrics_enabled, true)
        metric_name                = try(rule.value.visibility_config.metric_name, "${local.name}-${rule.value.name}")
        sampled_requests_enabled   = try(rule.value.visibility_config.sampled_requests_enabled, true)
      }

    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name}-rule-group"
    sampled_requests_enabled   = true
  }

  tags = local.tags
}
