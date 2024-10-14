# Terraform AWS CloudFront Distribution with AWS WAF

This repository contains Terraform code to provision an AWS CloudFront distribution with a custom origin. It includes the configuration for an AWS WAF (Web Application Firewall) with custom policies such as "Core Ruleset," "IP Reputation List," and a "Rate Limit" set to 1000 requests.

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
    cd aws-waf/wafwithcloudfront
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

The [variables.tf](https://github.com/Mobilinga002/aws-waf/blob/a1e8e02dbb855fb0d9552f452e84500719182f18/wafwithcloudfront/terraform.tf) file contains configurable inputs for the Terraform configuration, including the custom origin for the CloudFront distribution.

To customize the origin or any other variables, edit the `variables.tf`.

```bash
variable "origin_domain" {
  description = "Origin where cloudfront will copy and serve data"
  type        = string
  default     = "Your_Domain" 
}
```


## AWS WAF Configuration

The AWS WAF is configured with custom policies including:

- Core Ruleset
- IP Reputation List
- Rate Limiting to 1000 requests

These configurations are defined in the [waf.tf](https://github.com/Mobilinga002/aws-waf/blob/b381d206f0e9de6e217e7573c281bba2ec85ca1b/wafwithcloudfront/waf.tf) file and can be adjusted as necessary.

## Outputs

After applying the Terraform configuration, we will get `cloudfront_distribution_domain` as an output.

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
docker pull wallarm/gotestwaf
```

2. Run the Test: Execute the test using the following Docker command. Replace <cloudfront_domain_url> with your CloudFront distribution's URL:

```bash
docker run --rm -it -v "$(pwd):/app/reports" wallarm/gotestwaf --url=https://<cloudfront_domain_url>
```

