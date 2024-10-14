# Terraform AWS S3 CloudFront Distribution & Cognito User Pool with AWS WAF

This repository contains Terraform code to provision an AWS S3 CloudFront distribution & Cognito User Pool. It includes the configuration for an AWS WAF (Web Application Firewall) with custom policies such as "Core Ruleset," "IP Reputation List," and a "Rate Limit" set to 1000 requests.

## Prerequisites

Before you begin, ensure you have the following:

- An AWS account with the necessary permissions to create the resources listed above.
- Terraform installed on your local machine.
- AWS CLI configured with appropriate access.

## Getting Started

1. Clone this repository to your local machine.

    ```bash
    git clone https://github.com/Mobilinga002/aws-waf.git
    ```

2. Navigate into the repository directory.

    ```bash
    cd aws-waf/wafwithcloudfrontandcognito
    ```

3. Initialize the Terraform environment.

    ```bash
    terraform init
    ```

4. Review the Terraform plan to understand resources created/modified.

    ```bash
    terraform plan
    ```

5. Apply the Terraform code to provision the resources.

    ```bash
    terraform apply --auto-approve
    ```

## Configuring the Variables

The [variables.tf](https://github.com/Mobilinga002/aws-waf/blob/bbf8ecb99b491b1f20e2b54aa465467837d661aa/wafwithcloudfrontandcognito/variables.tf) file contains configurable inputs for the Terraform configuration to create an Unique S3 bucket.

To customize the origin or any other variables, edit the `variables.tf`.

```bash
variable "s3_name" {
  default = "s3bucket-cloudfront-testing"
}
```


## AWS WAF Configuration

The AWS WAF is configured with custom policies including:

- Core Ruleset
- IP Reputation List
- Rate Limiting to 1000 requests
  
## Outputs

After applying the Terraform configuration, we will get `cloudfront_distribution_domain` & `cognito_user_pool_login_page_url` as an output.

## WAF Testing

This guide details the steps to test a CloudFront distribution with an attached AWS WAF by using Docker and Wallarm's GoTestWAF.

### Prerequisites

- Docker installed on your local machine.
- An AWS CloudFront with AWS WAF configured and available for testing.
- Command-line access.

### Installation

GoTestWAF is a tool designed to evaluate the effectiveness of a WAF solution by sending a variety of test payloads and reporting on the results.

1. Pull GoTestWAF Docker Image: Ensure that you have the latest GoTestWAF image by running.

```bash
docker pull jadonharsh/gotestwaf
```

2. Run the Test: Execute the test using the following Docker command. Replace <cloudfront_domain_url> with your CloudFront distribution's URL:

```bash
docker run --rm -it -v "$(pwd):/app/reports" jadonharsh/gotestwaf --url=https://<cloudfront_distribution_domain>
docker run --rm -it -v "$(pwd):/app/reports" jadonharsh/gotestwaf --url=https://<cognito_auth_url>
```

