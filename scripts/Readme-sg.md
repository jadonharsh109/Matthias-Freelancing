# AWS Security Group Inbound Rules Check - `sg.sh`

This script inspects the inbound rules of AWS Security Groups in a specified region. It ensures that AWS CLI and `jq` are installed and configured before retrieving Security Group information.

## Prerequisites

- AWS CLI installed and configured with the necessary access rights.
- `jq` command-line JSON processor.

## Installation

1. Clone the repository or download the `sg.sh` file directly.
2. Make the script executable:
   ```bash
   chmod +x sg.sh
## Usage

1. Run the script with the command:
    ```bash
    ./sg.sh
2. Follow the prompts in the script to enter the AWS region you wish to check.

## Script Output

The script will list each Security Group ID along with its inbound rules in the specified region.

## Error Handling
The script has built-in checks that will:

- Alert if AWS CLI or jq is not installed.
- Validate the specified AWS region.
- Ensure you have the right permissions to list Security Groups.
