#!/bin/bash

echo "Starting the Network ACL retrieval process..."

# Check for the presence of required commands: aws and jq
if ! command -v aws &> /dev/null; then
    echo "Error: The AWS CLI is not installed. Please install it to run this script."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it to run this script."
    exit 1
fi

# Function to fetch and filter Network ACL details
fetch_network_acls_details() {
    local cidr_range="$1"
    local region="$2"
    local aws_options=()
    [ -n "$region" ] && aws_options+=(--region "$region")
    local network_acls_json=$(aws ec2 describe-network-acls "${aws_options[@]}" --output json 2>&1)
    local aws_exit_status=$?

    if [ $aws_exit_status -ne 0 ]; then
        echo "Error: Failed to retrieve Network ACLs. AWS CLI returned the following error:"
        echo "$network_acls_json"
        return $aws_exit_status
    fi

    # Parse JSON and replace protocol numbers with names
    local network_acls_text=$(echo "$network_acls_json" | jq -r --arg CIDR "$cidr_range" '.NetworkAcls[] 
        | .NetworkAclId as $acl_id 
        | .Entries[] 
        | select((.CidrBlock // "") == $CIDR or (.Ipv6CidrBlock // "") == $CIDR) 
        | [$acl_id, .RuleNumber, (if .Egress then "Outbound" else "Inbound" end), .Protocol, (if .PortRange? then (.PortRange.From | tostring) + "-" + (.PortRange.To | tostring) else "All" end), (.CidrBlock // .Ipv6CidrBlock), (if .RuleAction == "allow" then "Allow" else "Deny" end)] 
        | @tsv' | while IFS=$'\t' read -r acl_id rule_num type proto port_range cidr action; do
            # Map protocol number to name
            if [ "$proto" -eq "-1" ]; then
                protocol_name="all"
            elif [ "$proto" -eq "1" ]; then
                protocol_name="icmp"
            elif [ "$proto" -eq "6" ]; then
                protocol_name="tcp"
            elif [ "$proto" -eq "17" ]; then
                protocol_name="udp"
            elif [ "$proto" -eq "58" ]; then
                protocol_name="icmpv6"
            # Add more protocol mappings with elif statements if necessary
            else
                protocol_name="$proto"
            fi
            printf "%-20s\t%-12s\t%-8s\t%-10s\t%-11s\t%-37s\t%-6s\n" "$acl_id" "$rule_num" "$type" "$protocol_name" "$port_range" "$cidr" "$action"
        done)

    # Output formatted details
    echo
    echo "Network ACL details for region ${region:-"all regions"}:"
    printf "%-20s\t%-12s\t%-8s\t%-10s\t%-11s\t%-37s\t%-6s\n" "Network ACL ID" "Rule Number" "Type" "Protocol" "Port Range" "CIDR/IPV6 Block" "Action"
    echo "-------------------------------------------------------------------------------------------------------------------------------------------"
    echo "$network_acls_text"
    echo "-------------------------------------------------------------------------------------------------------------------------------------------"
}

# Function to retrieve all available AWS regions
get_aws_regions() {
    aws ec2 describe-regions --query "Regions[].RegionName" --output text
}

# Main script execution
echo "Please enter the AWS region to search within (e.g., us-west-1), or press Enter to search all regions:"
read -r region_input

echo "Please enter a CIDR range to filter by (e.g., 192.168.1.0/24 or 2001:db8::/32), or press Enter to list all Network ACLs:"
read -r cidr_input

# If a region is provided, search only that region; otherwise loop through all regions
if [ -n "$region_input" ]; then
    fetch_network_acls_details "$cidr_input" "$region_input"
else
    echo "No region provided; searching all regions..."
    regions=$(get_aws_regions)
    for region in $regions; do
        echo "Searching in region: $region..."
        if ! fetch_network_acls_details "$cidr_input" "$region"; then
            echo "No Network ACLs found for region $region."
        fi
    done
fi

echo

# Fetch AWS account ID
account_id=$(aws sts get-caller-identity --query "Account" --output text)

# Get the current time
current_time=$(date +%Y-%m-%d\ %H:%M:%S)

# Display account ID and the time of script execution
echo "AWS Account ID: $account_id"
echo "Time of script execution: $current_time"

echo "Script execution completed."