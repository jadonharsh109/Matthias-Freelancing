resource "aws_wafv2_web_acl" "web_acl" {
  name  = "web-acl-for-user-pool"
  scope = "CLOUDFRONT"

  # Default action is to allow requests
  default_action {
    allow {}
  }

  # Configuration to send metrics to CloudWatch
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "terraform-waf-metrics"
    sampled_requests_enabled   = true
  }

  # Rule using managed AWS IP reputation list
  rule {
    name     = "AWSIPReputationList"
    priority = 0

    # No override action is specified
    override_action {
      none {}
    }

    # Use a managed rule group for IP reputation checking provided by AWS
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    # CloudWatch metrics configuration for the IP reputation list rule
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSIPReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Rule for AWS Managed Rules Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    # No override action is specified
    override_action {
      none {}
    }

    # Use a managed rule group for common rule set provided by AWS
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    # CloudWatch metrics configuration for the common rule set
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }
}
