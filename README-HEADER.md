# PBS TF WAFv2 Rule Group Module

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-wafv2-rule-group-module?ref=x.y.z
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
- `or_statements` — OR of ip_set_ref / byte_match sub-statements
- `and_not_regex_geo` — AND(NOT(regex), geo) compound pattern

Integrate this module like so:

```hcl
module "wafv2_rule_group" {
  source = "github.com/pbs/terraform-aws-wafv2-rule-group-module?ref=x.y.z"

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

`x.y.z`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs
