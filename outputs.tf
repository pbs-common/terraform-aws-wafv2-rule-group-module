output "rule_group_arn" {
  description = "ARN of the WAFv2 rule group. Pass to the fms-policy-module managed_service_data."
  value       = aws_wafv2_rule_group.this.arn
}

output "rule_group_id" {
  description = "ID of the WAFv2 rule group."
  value       = aws_wafv2_rule_group.this.id
}

output "ip_set_arns" {
  description = "Map of IP set key => ARN for all IP sets created by this module."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.arn }
}

output "ip_set_ids" {
  description = "Map of IP set key => ID for all IP sets created by this module."
  value       = { for k, v in aws_wafv2_ip_set.this : k => v.id }
}

output "regex_pattern_set_arns" {
  description = "Map of regex pattern set key => ARN for all regex pattern sets created by this module."
  value       = { for k, v in aws_wafv2_regex_pattern_set.this : k => v.arn }
}

output "name" {
  description = "Resolved name prefix used by all resources."
  value       = local.name
}

output "tags" {
  description = "Tags applied to all resources."
  value       = local.tags
}
