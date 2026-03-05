module "wafv2_rule_group" {
  source = "../.."

  scope    = "REGIONAL"
  capacity = 120

  ip_sets = {
    blacklist = {
      description = "IPs blocked unconditionally"
      addresses   = ["192.0.2.1/32"]
    }
    allowlist = {
      description = "Known-good IPs allowed unconditionally"
      addresses   = ["203.0.113.0/24"]
    }
  }

  rules = [
    # Block all blacklisted IPs (WCU: 1)
    {
      name       = "block-blacklisted-ips"
      priority   = 0
      action     = "block"
      ip_set_ref = { key = "blacklist" }
    },

    # Allow allowlisted IPs OR requests carrying a bypass header (WCU: 1 + 10 = 11)
    {
      name     = "allow-allowlisted-ips-or-bypass"
      priority = 1
      action   = "allow"
      or_statements = [
        { ip_set_ref_key = "allowlist" },
        {
          byte_match = {
            search_string         = "my-bypass-secret"
            positional_constraint = "EXACTLY"
            field_to_match        = { type = "single_header", name = "x-bypass-secret" }
          }
        },
      ]
    },

    # Block a simple set of high-risk countries (WCU: 1)
    {
      name     = "block-high-risk-countries"
      priority = 3
      action   = "block"
      geo_match = {
        country_codes = ["KP", "CU", "IR", "SY"]
      }
    },

    # Rate-limit POST requests per source IP (WCU: 2 + 10 = 12)
    {
      name     = "rate-limit-post"
      priority = 10
      action   = "block"
      rate_based = {
        limit                 = 300
        evaluation_window_sec = 300
        aggregate_key_type    = "IP"
        scope_down = {
          byte_match = {
            search_string         = "POST"
            positional_constraint = "EXACTLY"
            field_to_match        = { type = "method" }
          }
        }
      }
    },

    # General rate limit for all other traffic (WCU: 2)
    {
      name     = "rate-limit-all"
      priority = 20
      action   = "block"
      rate_based = {
        limit                 = 3000
        evaluation_window_sec = 300
        aggregate_key_type    = "IP"
      }
    },
  ]

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  owner        = var.owner
  repo         = var.repo

  # Optional Parameters
}
