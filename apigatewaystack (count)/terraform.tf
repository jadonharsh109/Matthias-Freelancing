provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "The AWS region to create resources."
  type        = string
  default     = "us-east-1"
}



