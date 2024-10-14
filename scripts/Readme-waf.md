# AWS WAF Web ACLs Inspector - `waf.sh`

This script facilitates the inspection and reporting of Web Access Control Lists (ACLs) in AWS WAF. Using the scope provided by the user, it lists all associated Web ACLs and provides details on each, including referenced IP sets and actions (Allow/Block).

## Prerequisites

To use `waf.sh`, you must have the following prerequisites ready:
- **AWS CLI**: Configured with the necessary AWS credentials.
- **jq**: Installed to process JSON data.

## Installation

Follow these steps to prepare the script for execution:
1. Download `waf.sh` or clone the entire repository.
2. Navigate to the folder containing `waf.sh`.
3. Grant execution permissions to the script:
   ```bash
   chmod +x waf.sh
## Usage
1. Execute the script in your terminal with the command:
    ```bash
    ./waf.sh
2. Enter the scope of the Web ACLs when prompted (CLOUDFRONT or REGIONAL).

## Script Output
waf.sh will provide the names and IDs of the Web ACLs within the specified scope as well as any associated IP set references and their actions (Allow/Block). It will also list the IP ranges defined in each IP set.

## Error Handling
The script gracefully handles common errors by:

- Checking the presence and correct configuration of the AWS CLI and jq.
- Validating the scope provided by the user.
- Managing AWS CLI output errors and permissions issues.
