output "AWS_CLI_Describe_Web_ACLs" {
  value = "aws wafv2 get-web-acl --name ${aws_wafv2_web_acl.web_acl_cloudfront.name} --scope ${aws_wafv2_web_acl.web_acl_cloudfront.scope} --id ${aws_wafv2_web_acl.web_acl_cloudfront.id}"
}

output "AWS_CLI_Describe_IP_Sets" {
  value = "aws wafv2 get-ip-set --name ${aws_wafv2_ip_set.whitelist_ip_set.name} --scope ${aws_wafv2_ip_set.whitelist_ip_set.scope} --id ${aws_wafv2_ip_set.whitelist_ip_set.id}"
}

# Output the domain name of the CloudFront distribution.
output "cloudfront_distribution_domain_name" {
  value = "https://${aws_cloudfront_distribution.api_gateway_cloudfront.domain_name}" # The domain name URL for the CloudFront distribution.
}
output "URL" {
  value = "https://${aws_cloudfront_distribution.api_gateway_cloudfront.domain_name}/v1/hello" # The domain name URL for the CloudFront distribution.
}
