# Terraform Script for AWS API Gateway, CloudFront, and WAF Integration

This repository contains a Terraform script to provision an AWS API Gateway and integrate it with CloudFront and WAF. This setup provides a secure, scalable API interface with a global content delivery network (CDN) service and a Web Application Firewall for enhanced security.
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
    cd aws-waf/apigatewaystack
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

To customize the API Gateway Endpoint Type, comment out the below lines in `apigateway.tf` to make `TYPE: EDGE`.

```bash
  endpoint_configuration {
    types = ["REGIONAL"]
  }
```


## AWS WAF Configuration

The AWS WAF is configured with custom policies including:

- Core Ruleset
- IP Reputation List
- Rate Limiting to 1000 requests
  
## Outputs

After applying the Terraform configuration, we will get `cloudfront_distribution_domain_name` & `URL` as an output.

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
docker run --rm -it -v "$(pwd):/app/reports" jadonharsh/gotestwaf --url=<URL>
```

