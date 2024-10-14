# This resource creates an AWS WAFv2 Web Access Control List (Web ACL) which acts as a layer of security.
resource "aws_wafv2_web_acl" "web_acl_cloudfront" {
  name  = "web-acl-for-cloudfront" # Name of the Web ACL
  scope = "CLOUDFRONT"             # Indicates the Web ACL is intended for use with CloudFront. 

  # Default action the Web ACL will take on a request that does not match any rules, which is to allow the request.
  default_action {
    block {} # Specifies that requests should be blocked by default unless they match the whitelist rule.
  }

  # Settings to define how the Web ACL will display in AWS CloudWatch, enabling logging and metrics.
  visibility_config {
    cloudwatch_metrics_enabled = true                     # Enables CloudWatch metrics for the Web ACL.
    metric_name                = "cloudfront-waf-metrics" # Name of the metric to be used in CloudWatch.
    sampled_requests_enabled   = true                     # Enables logging of sampled requests-which are detailed records about requests.
  }

  rule {
    name     = "WhitelistIPRule"
    priority = 0

    action {
      allow {} # This rule allows requests from IP(s) specified in the IP set.
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
  # First rule that uses a managed rule group provided by AWS, specifically for IP reputation checking.
  rule {
    name     = "AWSIPReputationList" # Name of this specific rule.
    priority = 1                     # Priority for the order rules are evaluated. Lower numbers are evaluated first.

    # Action overrides are not used here, so this rule's action will follow the default from the rule group.
    override_action {
      none {} # Indicates there is no override action.
    }

    # Specifies the use of a managed rule group for this rule.
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList" # Rule group for checking the reputation of the IP.
        vendor_name = "AWS"                                   # The vendor name providing the rule group.
      }
    }

    # Metrics and logging configuration specific to this rule.
    visibility_config {
      cloudwatch_metrics_enabled = true                  # Enables CloudWatch metrics.
      metric_name                = "AWSIPReputationList" # Name of the metric.
      sampled_requests_enabled   = true                  # Enables detailed request logging.
    }
  }

  # Second rule incorporating common set of managed rules for common threats.
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
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

  # Third rule to create a simple rate-based rule for limiting requests from a single IP for DDoS protection.
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {} # Action to block requests that exceed the rate limit.
    }

    statement {
      rate_based_statement {
        limit              = 1000 # Maximum number of allowable requests from a single IP within a five-minute period.
        aggregate_key_type = "IP" # Setting the aggregate key on which to base the rate limit - IP address.
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


