resource "aws_wafv2_web_acl" "web_acl_cloudfront" {
  name  = "web-acl-for-cloudfront"
  scope = "CLOUDFRONT"

  # Default action the Web ACL will take on a request that does not match any rules, which is to count the request.
  default_action {
    allow {} # Specifies that requests should be alllow by the ACL.
  }

  # Visibility configuration for CloudWatch metrics and sampled requests.
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf-metrics"
    sampled_requests_enabled   = true
  }

  # Rule to count requests from specific IPs.
  rule {
    name     = "WhitelistIPRule"
    priority = 0

    action {
      count {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.whitelist_ip_set.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "WhitelistIPRule"
      sampled_requests_enabled   = true
    }
  }

  # Rule using a managed IP reputation rule group.
  rule {
    name     = "AWSIPReputationList"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSIPReputationList"
      sampled_requests_enabled   = true
    }
  }

  # Rule using AWS managed rules common set.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule for limiting request rates.
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      count {} # Action to count requests that exceed the rate limit.
    }

    statement {
      rate_based_statement {
        limit              = 1000
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

resource "aws_wafv2_ip_set" "whitelist_ip_set" {
  name               = "whitelist-ip-set"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.whitelisted_ips
}
