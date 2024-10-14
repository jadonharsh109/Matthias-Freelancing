# AWS Infrastructure as Code (IaC) with Terraform

This project encompasses the development of Infrastructure as Code (IaC) solutions using Terraform to deploy a range of AWS services seamlessly and efficiently. The primary focus is on implementing a robust AWS WAF & Shield setup integrated with AWS Cognito, S3, CloudFront, and API Gateway.

## Features

- **AWS WAF & Shield Implementation**: Secure your AWS resources using WAF (Web Application Firewall) with custom rules and configurations.
  - Integration with AWS services: Cognito, S3, CloudFront, and API Gateway.
  - Comprehensive rule setup including IP whitelisting, rate limiting, IP reputation management, and a core rule set application.
  
- **Security Testing**: Thoroughly tested AWS WAF setup using GoTestWaf to assess network traffic for vulnerabilities and performance issues.
  
- **Advanced Reporting**: Developed shell scripts to generate detailed reports on WAF, Security Groups, and Network Access Control Lists.
  - Includes functionality to specify and analyze CIDR ranges.

## Prerequisites

- [Terraform](https://www.terraform.io/)
- AWS Account
- [GoTestWaf](https://github.com/wallarm/gotestwaf) for testing

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/jadonharsh109/Matthias-Freelancing.git
   cd Matthias-Freelancing

2. Configure your AWS credentials:
   ```bash
   aws configure

## Usage

- Customize WAF rules in the Terraform configurations as per your needs.
- Use the provided scripts to analyze current security settings and extract reports.

## Contributing
Feel free to raise issues or contribute to this project by opening pull requests. Make sure to adhere to the contribution guidelines.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contact
Please contact jadonharsh109@gmail.com for questions and collaboration.




