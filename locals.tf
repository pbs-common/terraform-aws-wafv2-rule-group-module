locals {
  name    = var.name != null ? var.name : var.product
  creator = "terraform"

  defaulted_tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      "${var.organization}:owner"               = var.owner
      creator                                   = local.creator
      repo                                      = var.repo
    }
  )

  tags = merge({ for k, v in local.defaulted_tags : k => v if lookup(data.aws_default_tags.common_tags.tags, k, "") != v })

  # Resolved ARN lookups so rules can reference resources by map key
  ip_set_arns            = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
  regex_pattern_set_arns = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }

  # Default text_transformation when the caller omits text_transformations
  default_ttx = [{ priority = 0, type = "NONE" }]
}

data "aws_default_tags" "common_tags" {}
