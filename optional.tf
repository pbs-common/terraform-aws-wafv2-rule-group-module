variable "name" {
  description = "Name prefix applied to all resources. If null, defaults to var.product."
  default     = null
  type        = string
}

# ─── IP sets ──────────────────────────────────────────────────────────────────

variable "ip_sets" {
  description = <<-EOT
    Map of IP sets to create. The map key is a reference handle used in rule
    definitions (ip_set_ref.key, or_statements[*].ip_set_ref_key,
    rate_based.scope_down.ip_set_ref_key).

    Attributes:
      description        — human-readable description
      ip_address_version — IPV4 or IPV6 (default: IPV4)
      addresses          — list of CIDR notation strings
  EOT
  type = map(object({
    description        = string
    ip_address_version = optional(string, "IPV4")
    addresses          = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.ip_sets : contains(["IPV4", "IPV6"], v.ip_address_version)])
    error_message = "ip_sets[*].ip_address_version must be IPV4 or IPV6."
  }
}

# ─── Regex pattern sets ───────────────────────────────────────────────────────

variable "regex_pattern_sets" {
  description = <<-EOT
    Map of regex pattern sets to create. The map key is a reference handle used in
    rule definitions (regex_set_ref.key).

    Attributes:
      description         — human-readable description
      regular_expressions — list of PCRE regex strings
  EOT
  type = map(object({
    description         = string
    regular_expressions = list(string)
  }))
  default = {}
}

# ─── Rules ────────────────────────────────────────────────────────────────────

variable "rules" {
  description = <<-EOT
    Ordered list of WAFv2 rules. Set exactly one statement type per rule.

    Supported statement types:
      ip_set_ref        — matches source IP against an IP set (key into var.ip_sets)
      byte_match        — string match on a request field
      geo_match         — matches source country codes
      regex_match       — inline PCRE regex match on a request field
      regex_set_ref     — regex pattern set match (key into var.regex_pattern_sets)
      rate_based        — rate-based with optional scope-down and forwarded-IP support
      or_statements     — OR of sub-statements (ip_set_ref_key or byte_match)
      and_not_regex_geo — AND(NOT(regex_match), geo_match) compound pattern

    field_to_match.type options:
      uri_path, method, body, query_string, all_query_arguments,
      single_header (+ field_to_match.name required),
      single_query_argument (+ field_to_match.name required)

    action options:             allow, block, count
    positional_constraint:      EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, CONTAINS_WORD
    rate_based.aggregate_key_type: IP, FORWARDED_IP
    rate_based.evaluation_window_sec: 60, 120, 300, 600
  EOT

  type = list(object({
    name     = string
    priority = number
    action   = string # allow | block | count

    ip_set_ref = optional(object({
      key = string
    }))

    byte_match = optional(object({
      search_string         = string
      positional_constraint = string
      field_to_match = object({
        type = string
        name = optional(string)
      })
      text_transformations = optional(list(object({
        priority = number
        type     = string
      })))
    }))

    geo_match = optional(object({
      country_codes = list(string)
    }))

    regex_match = optional(object({
      regex_string = string
      field_to_match = object({
        type = string
        name = optional(string)
      })
      text_transformations = optional(list(object({
        priority = number
        type     = string
      })))
    }))

    regex_set_ref = optional(object({
      key = string
      field_to_match = object({
        type = string
        name = optional(string)
      })
      text_transformations = optional(list(object({
        priority = number
        type     = string
      })))
    }))

    rate_based = optional(object({
      limit                 = number
      evaluation_window_sec = optional(number, 300)
      aggregate_key_type    = optional(string, "IP")
      forwarded_ip_config = optional(object({
        header_name       = string
        fallback_behavior = optional(string, "MATCH")
      }))
      scope_down = optional(object({
        ip_set_ref_key        = optional(string)
        geo_country_codes     = optional(list(string))
        not_geo_country_codes = optional(list(string))
        byte_match = optional(object({
          search_string         = string
          positional_constraint = string
          field_to_match = object({
            type = string
            name = optional(string)
          })
          text_transformations = optional(list(object({
            priority = number
            type     = string
          })))
        }))
      }))
    }))

    or_statements = optional(list(object({
      ip_set_ref_key = optional(string)
      byte_match = optional(object({
        search_string         = string
        positional_constraint = string
        field_to_match = object({
          type = string
          name = optional(string)
        })
        text_transformations = optional(list(object({
          priority = number
          type     = string
        })))
      }))
    })))

    and_not_regex_geo = optional(object({
      regex_string = string
      field_to_match = object({
        type = string
        name = optional(string)
      })
      text_transformations = optional(list(object({
        priority = number
        type     = string
      })))
      country_codes = list(string)
    }))

    visibility_config = optional(object({
      cloudwatch_metrics_enabled = optional(bool, true)
      metric_name                = optional(string)
      sampled_requests_enabled   = optional(bool, true)
    }))
  }))

  default = []

  validation {
    condition     = alltrue([for r in var.rules : contains(["allow", "block", "count"], r.action)])
    error_message = "rules[*].action must be one of: allow, block, count."
  }
}
