# Create an AWS Cognito User Pool with specified name and auto-verification of email
resource "aws_cognito_user_pool" "user_pool" {
  name                     = "my-user-pool"
  auto_verified_attributes = ["email"]

  # Configuration settings for sending emails from Cognito
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT" # Uses Cognito's default email capability
  }
}

# Creates a Cognito user pool domain with a specific domain name linked to the user pool
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = "testingwithwaf"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# Creates a Cognito User Pool Client with various OAuth and authentication settings
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name         = "testingwithwaf-app-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  generate_secret                      = false                                                                    # Indicates that no client secret should be generated
  allowed_oauth_flows                  = ["implicit"]                                                             # Specifies an implicit OAuth flow
  allowed_oauth_flows_user_pool_client = true                                                                     # Allows OAuth flows enabled for the user pool client
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"] # Defines the allowed OAuth scopes
  callback_urls                        = [var.callback_url]                                                       # URLs for redirecting after authentication
  logout_urls                          = [var.signout_url]                                                        # URLs for redirection after signing out
  supported_identity_providers         = ["COGNITO"]                                                              # States that the Cognito is the only identity provider
  default_redirect_uri                 = var.callback_url
  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ] # Specifies the allowed authentication flows for the user pool
}

# Create an AWS WAFv2 Web ACL with rules to protect the user pool
resource "aws_wafv2_web_acl" "web_acl" {
  name  = "web-acl-for-user-pool"
  scope = "REGIONAL"

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
      count {}
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
      count {}
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
}

# Associate the created web ACL with the Cognito user pool
resource "aws_wafv2_web_acl_association" "user_pool_acl_association" {
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
  resource_arn = aws_cognito_user_pool.user_pool.arn
}

# Output the constructed Cognito authentication URL
output "cognito_auth_url" {
  value = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/authorize"
}

# Output the Cognito User Pool Client ID
output "cognito_client_ID" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "cognito_user_pool_login_page_url" {
  value       = "https://${aws_cognito_user_pool_domain.user_pool_domain.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.user_pool_client.id}&response_type=token&scope=${join("%20", aws_cognito_user_pool_client.user_pool_client.allowed_oauth_scopes)}&redirect_uri=${var.callback_url}"
  description = "The URL of the Cognito User Pool login page"
}

