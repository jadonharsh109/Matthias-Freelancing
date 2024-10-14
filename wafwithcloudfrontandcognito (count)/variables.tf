variable "callback_url" {
  description = "The callback URL after the user signs in"
  type        = string
  default     = "https://oauth.pstmn.io/v1/callback"
}

variable "signout_url" {
  description = "The Signout URL after the user loged out"
  type        = string
  default     = "https://oauth.pstmn.io/v1/logout"
}
variable "aws_region" {
  description = "The AWS region to create resources."
  type        = string
  default     = "us-east-1"
}
variable "s3_name" {
  default = "s3bucket-cloudfront-testing-5"
}
variable "cognito_domain_name" {
  default = "testing-waf-001"
}

