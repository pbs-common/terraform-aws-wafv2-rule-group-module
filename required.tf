variable "scope" {
  description = <<-EOT
    WAFv2 scope.
      REGIONAL   — ALBs, API Gateway, AppSync (deploy in any region).
      CLOUDFRONT — CloudFront distributions (must deploy in us-east-1).
  EOT
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "scope must be REGIONAL or CLOUDFRONT."
  }
}

variable "capacity" {
  description = <<-EOT
    Total WCU (Web ACL Capacity Units) budget for the rule group.
    Must be >= the sum of all rules WCU cost.
    Approximate WCU costs: ip_set_ref=1, byte_match=10, geo_match=1,
    regex_match=50, rate_based=2, or/and/not add nested costs.
  EOT
  type        = number
}
