# This data source fetches the existing information of an API Gateway REST API by its name.
data "aws_api_gateway_rest_api" "MyDemoAPI" {
  name = "HelloWorldAPI" # Name of the API to fetch

  # This ensures that the API Gateway deployment is created before this data source is read.
  depends_on = [
    aws_api_gateway_deployment.HelloWorldDeployment,
  ]
}

# This resource creates a CloudFront distribution for the API Gateway to allow CDN caching and distribution.
resource "aws_cloudfront_distribution" "api_gateway_cloudfront" {
  # Associates a Web ACL for access control (in this case assuming aws_wafv2_web_acl is defined somewhere else)
  web_acl_id = aws_wafv2_web_acl.web_acl_cloudfront.arn

  # Defines the origin of the CloudFront distribution.

  # Defines the origin of the CloudFront distribution.
  origin {
    # The domain name for a regional endpoint includes the API ID and the region
    domain_name = "${data.aws_api_gateway_rest_api.MyDemoAPI.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_id   = "API-Gateway-${data.aws_api_gateway_rest_api.MyDemoAPI.id}"

    # Configuration for the communication between CloudFront and the API Gateway origin.
    custom_origin_config {
      http_port              = 80           # Port used for HTTP.
      https_port             = 443          # Port used for HTTPS.
      origin_protocol_policy = "https-only" # Enforces HTTPS communication only.
      origin_ssl_protocols   = ["TLSv1.2"]  # Sets allowed SSL/TLS protocols.
    }
  }


  # General settings for the CloudFront distribution.
  enabled             = true                                      # Enables the distribution.
  is_ipv6_enabled     = true                                      # Enables IPv6.
  comment             = "CloudFront distribution for API Gateway" # A descriptive comment.
  default_root_object = ""                                        # Default object (not necessary for API Gateway).

  # Defines cache behaviors and allowed HTTP methods.
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"] # Methods which CloudFront will cache.
    target_origin_id = "API-Gateway-${data.aws_api_gateway_rest_api.MyDemoAPI.id}"

    # Configuration for forwarding to the origin.
    forwarded_values {
      query_string = false      # Whether to forward the query string to the origin.
      headers      = ["Origin"] # Whitelisted headers to forward.

      # Configuration for forwarding cookies.
      cookies {
        forward = "none" # Do not forward cookies.
      }
    }

    # Redirect all viewers to HTTPS.
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0     # Minimum amount of time CloudFront will cache objects.
    default_ttl            = 3600  # Default amount of time (in seconds) that an object is in a CloudFront cache.
    max_ttl                = 86400 # Maximum amount of time (in seconds) that an object is in a CloudFront cache.
  }

  # Price class setting for CloudFront (affects how global the distribution is).
  price_class = "PriceClass_All"

  # Geo restrictions configuration (currently set to no restrictions).
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuration for SSL/TLS certificates (defaults to using CloudFront's certificate).
  viewer_certificate {
    cloudfront_default_certificate = true # Use the default CloudFront SSL/TLS certificate.
  }
}



