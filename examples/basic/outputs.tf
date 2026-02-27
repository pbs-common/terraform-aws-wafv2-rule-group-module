output "rule_group_arn" {
  description = "ARN of the WAFv2 rule group"
  value       = module.wafv2_rule_group.rule_group_arn
}

output "rule_group_id" {
  description = "ID of the WAFv2 rule group"
  value       = module.wafv2_rule_group.rule_group_id
}

output "ip_set_arns" {
  description = "Map of IP set key => ARN"
  value       = module.wafv2_rule_group.ip_set_arns
}

output "tags" {
  description = "Tags applied to all resources"
  value       = module.wafv2_rule_group.tags
}
