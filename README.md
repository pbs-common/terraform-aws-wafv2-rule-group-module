# PBS TF WAFv2 Rule Group Module

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-wafv2-rule-group-module?ref=0.0.3
```

### Alternative Installation Methods

More information can be found on these install methods and more in [the documentation here](./docs/general/install).

## Usage

Creates a WAFv2 regional or CloudFront rule group together with all supporting resources
(IP sets, regex pattern sets). Rules are expressed as a declarative list — no hard-coded
rule logic lives inside the module, making the module reusable across
environments and products.

Supported statement types per rule:
- `ip_set_ref` — IP set block/allow by key
- `byte_match` — string match on any request field
- `geo_match` — country-code block
- `regex_match` — inline PCRE regex
- `regex_set_ref` — managed regex pattern set reference
- `rate_based` — rate limiting with optional forwarded-IP and scope-down
- `or_statements` — OR of ip\_set\_ref / byte\_match sub-statements
- `and_not_regex_geo` — AND(NOT(regex), geo) compound pattern

Integrate this module like so:

```hcl
module "wafv2_rule_group" {
  source = "github.com/pbs/terraform-aws-wafv2-rule-group-module?ref=0.0.3"

  scope    = "REGIONAL"
  capacity = 200

  ip_sets = {
    blacklist = {
      description = "IPs blocked unconditionally"
      addresses   = ["1.2.3.4/32"]
    }
    allowlist = {
      description = "Known-good IPs allowed unconditionally"
      addresses   = ["203.0.113.0/24"]
    }
  }

  rules = [
    {
      name      = "block-blacklisted-ips"
      priority  = 0
      action    = "block"
      ip_set_ref = { key = "blacklist" }
    },
    {
      name     = "allow-allowlisted-ips"
      priority = 1
      action   = "allow"
      ip_set_ref = { key = "allowlist" }
    },
    {
      name     = "rate-limit-all"
      priority = 10
      action   = "block"
      rate_based = {
        limit              = 3000
        aggregate_key_type = "IP"
      }
    },
  ]

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo

  # Optional Parameters
}
```

## Adding This Version of the Module

If this repo is added as a subtree, then the version of the module should be
close to the version shown here:

`0.0.3`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.34.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_wafv2_ip_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_regex_pattern_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_regex_pattern_set) | resource |
| [aws_wafv2_rule_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_rule_group) | resource |
| [aws_default_tags.common_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (sharedtools, dev, staging, qa, prod) | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization using this module. Used to prefix tags so that they are easily identified as being from your organization | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Tag used to group resources according to owner | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Tag used to point to the repo using this module | `string` | n/a | yes |
| <a name="input_capacity"></a> [capacity](#input\_capacity) | Total WCU (Web ACL Capacity Units) budget for the rule group.<br/>Must be >= the sum of all rules WCU cost.<br/>Approximate WCU costs: ip\_set\_ref=1, byte\_match=10, geo\_match=1,<br/>regex\_match=50, rate\_based=2, or/and/not add nested costs. | `number` | `500` | no |
| <a name="input_ip_sets"></a> [ip\_sets](#input\_ip\_sets) | Map of IP sets to create. The map key is a reference handle used in rule<br/>definitions (ip\_set\_ref.key, or\_statements[*].ip\_set\_ref\_key,<br/>rate\_based.scope\_down.ip\_set\_ref\_key).<br/><br/>Attributes:<br/>  description        — human-readable description<br/>  ip\_address\_version — IPV4 or IPV6 (default: IPV4)<br/>  addresses          — list of CIDR notation strings | <pre>map(object({<br/>    description        = string<br/>    ip_address_version = optional(string, "IPV4")<br/>    addresses          = optional(list(string), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix applied to all resources. If null, defaults to var.product. | `string` | `null` | no |
| <a name="input_regex_pattern_sets"></a> [regex\_pattern\_sets](#input\_regex\_pattern\_sets) | Map of regex pattern sets to create. The map key is a reference handle used in<br/>rule definitions (regex\_set\_ref.key).<br/><br/>Attributes:<br/>  description         — human-readable description<br/>  regular\_expressions — list of PCRE regex strings | <pre>map(object({<br/>    description         = string<br/>    regular_expressions = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | Ordered list of WAFv2 rules. Set exactly one statement type per rule.<br/><br/>Supported statement types:<br/>  ip\_set\_ref        — matches source IP against an IP set (key into var.ip\_sets)<br/>  byte\_match        — string match on a request field<br/>  geo\_match         — matches source country codes<br/>  regex\_match       — inline PCRE regex match on a request field<br/>  regex\_set\_ref     — regex pattern set match (key into var.regex\_pattern\_sets)<br/>  rate\_based        — rate-based with optional scope-down and forwarded-IP support<br/>  or\_statements     — OR of sub-statements (ip\_set\_ref\_key or byte\_match)<br/>  and\_not\_regex\_geo — AND(NOT(regex\_match), geo\_match) compound pattern<br/><br/>field\_to\_match.type options:<br/>  uri\_path, method, body, query\_string, all\_query\_arguments,<br/>  single\_header (+ field\_to\_match.name required),<br/>  single\_query\_argument (+ field\_to\_match.name required)<br/><br/>action options:             allow, block, count<br/>positional\_constraint:      EXACTLY, STARTS\_WITH, ENDS\_WITH, CONTAINS, CONTAINS\_WORD<br/>rate\_based.aggregate\_key\_type: IP, FORWARDED\_IP<br/>rate\_based.evaluation\_window\_sec: 60, 120, 300, 600 | <pre>list(object({<br/>    name     = string<br/>    priority = number<br/>    action   = string # allow | block | count<br/><br/>    ip_set_ref = optional(object({<br/>      key = string<br/>    }))<br/><br/>    byte_match = optional(object({<br/>      search_string         = string<br/>      positional_constraint = string<br/>      field_to_match = object({<br/>        type = string<br/>        name = optional(string)<br/>      })<br/>      text_transformations = optional(list(object({<br/>        priority = number<br/>        type     = string<br/>      })))<br/>    }))<br/><br/>    geo_match = optional(object({<br/>      country_codes = list(string)<br/>    }))<br/><br/>    regex_match = optional(object({<br/>      regex_string = string<br/>      field_to_match = object({<br/>        type = string<br/>        name = optional(string)<br/>      })<br/>      text_transformations = optional(list(object({<br/>        priority = number<br/>        type     = string<br/>      })))<br/>    }))<br/><br/>    regex_set_ref = optional(object({<br/>      key = string<br/>      field_to_match = object({<br/>        type = string<br/>        name = optional(string)<br/>      })<br/>      text_transformations = optional(list(object({<br/>        priority = number<br/>        type     = string<br/>      })))<br/>    }))<br/><br/>    rate_based = optional(object({<br/>      limit                 = number<br/>      evaluation_window_sec = optional(number, 300)<br/>      aggregate_key_type    = optional(string, "IP")<br/>      forwarded_ip_config = optional(object({<br/>        header_name       = string<br/>        fallback_behavior = optional(string, "MATCH")<br/>      }))<br/>      scope_down = optional(object({<br/>        ip_set_ref_key        = optional(string)<br/>        geo_country_codes     = optional(list(string))<br/>        not_geo_country_codes = optional(list(string))<br/>        byte_match = optional(object({<br/>          search_string         = string<br/>          positional_constraint = string<br/>          field_to_match = object({<br/>            type = string<br/>            name = optional(string)<br/>          })<br/>          text_transformations = optional(list(object({<br/>            priority = number<br/>            type     = string<br/>          })))<br/>        }))<br/>      }))<br/>    }))<br/><br/>    or_statements = optional(list(object({<br/>      ip_set_ref_key = optional(string)<br/>      byte_match = optional(object({<br/>        search_string         = string<br/>        positional_constraint = string<br/>        field_to_match = object({<br/>          type = string<br/>          name = optional(string)<br/>        })<br/>        text_transformations = optional(list(object({<br/>          priority = number<br/>          type     = string<br/>        })))<br/>      }))<br/>    })))<br/><br/>    and_not_regex_geo = optional(object({<br/>      regex_string = string<br/>      field_to_match = object({<br/>        type = string<br/>        name = optional(string)<br/>      })<br/>      text_transformations = optional(list(object({<br/>        priority = number<br/>        type     = string<br/>      })))<br/>      country_codes = list(string)<br/>    }))<br/><br/>    visibility_config = optional(object({<br/>      cloudwatch_metrics_enabled = optional(bool, true)<br/>      metric_name                = optional(string)<br/>      sampled_requests_enabled   = optional(bool, true)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | WAFv2 scope.<br/>  REGIONAL   — ALBs, API Gateway, AppSync (deploy in any region).<br/>  CLOUDFRONT — CloudFront distributions (must deploy in us-east-1). | `string` | `"REGIONAL"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ip_set_arns"></a> [ip\_set\_arns](#output\_ip\_set\_arns) | Map of IP set key => ARN for all IP sets created by this module. |
| <a name="output_ip_set_ids"></a> [ip\_set\_ids](#output\_ip\_set\_ids) | Map of IP set key => ID for all IP sets created by this module. |
| <a name="output_name"></a> [name](#output\_name) | Resolved name prefix used by all resources. |
| <a name="output_regex_pattern_set_arns"></a> [regex\_pattern\_set\_arns](#output\_regex\_pattern\_set\_arns) | Map of regex pattern set key => ARN for all regex pattern sets created by this module. |
| <a name="output_rule_group_arn"></a> [rule\_group\_arn](#output\_rule\_group\_arn) | ARN of the WAFv2 rule group. Pass to the fms-policy-module managed\_service\_data. |
| <a name="output_rule_group_id"></a> [rule\_group\_id](#output\_rule\_group\_id) | ID of the WAFv2 rule group. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to all resources. |
