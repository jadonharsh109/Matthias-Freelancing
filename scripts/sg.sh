#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI is not installed. Please install it and configure it before running this script."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it before running this script."
    exit 1
fi

# Ask the user for the region
read -p "Enter the region to check Security Groups (e.g., us-east-1): " region

# Check if the provided region is valid
if ! aws ec2 describe-regions --query 'Regions[].RegionName' --output text | grep -q "$region"; then
    echo "The region '$region' is not valid."
    exit 1
fi

# Retrieve list of all security group IDs in the specified region
group_ids=($(aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId' --output text --region "$region" 2>/dev/null))
if [ $? -ne 0 ]; then
    echo "Error retrieving security groups. Please ensure your AWS CLI is configured correctly, and that you have the necessary permissions."
    exit 1
elif [ -z "$group_ids" ]; then
    echo "No security groups found in region $region."
    exit 0
fi

# Iterate over each security group ID and get the associated rules
for group_id in "${group_ids[@]}"; do
    echo "Security Group ID: $group_id in region $region"
    
    ip_permissions=$(aws ec2 describe-security-groups --group-ids "$group_id" --query 'SecurityGroups[*].IpPermissions[]' --output json --region "$region" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error retrieving inbound rules for security group $group_id."
        continue
    elif [ -z "$ip_permissions" ] || [ "$ip_permissions" == "[]" ]; then
        echo "No inbound rules found for security group $group_id."
    else
        echo "Inbound Rules:"
        echo "$ip_permissions" | jq -r '.[] | "Protocol: \(.IpProtocol), From Port: \(.FromPort), To Port: \(.ToPort), IP Ranges: \(.IpRanges[].CidrIp)"' || {
            echo "Error parsing inbound rules for security group $group_id with jq."
            continue
        }
        echo ""
    fi
done
