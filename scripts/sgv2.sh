#!/bin/bash

# Helper functions
command_check() {
  if ! command -v "$1" &> /dev/null; then
    echo "$1 is not installed. Please install it and run this script again."
    exit 1
  fi
}

# Initial setup checks
command_check aws
command_check jq

# Echo the divider lines for clear formatting
print_divider() {
  echo "--------------------------------------------------------"
}

# Display formatted security group information
display_formatted_output() {
  local ip_permissions="$1"
  local group_id="$2"
  local region="$3"

  print_divider
  echo "Security Group ID: $group_id (Region: $region)"
  if [[ -z "$ip_permissions" || "$ip_permissions" == "[]" ]]; then
    echo "No inbound rules or no matching rules for the given CIDR/wildcard."
  else
    # Display inbound rules using jq
    echo "$ip_permissions" | jq -r '.[] | "Protocol: \(.IpProtocol) | From Port: \(.FromPort) | To Port: \(.ToPort) | IP Ranges: \(.IpRanges | map(.CidrIp) | join(", ")) | IPv6 Ranges: \(.Ipv6Ranges | map(.CidrIpv6) | join(", "))"'
  fi
  print_divider
  echo
}

# Process security groups per region
check_security_groups() {
  local region="$1"
  echo "Searching in region: $region..."

  local group_ids=($(aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId' --output text --region "$region" 2>/dev/null))
  if [ ${#group_ids[@]} -eq 0 ]; then
    echo "No security groups found in region $region."
    return
  fi

  local ip_permissions_query='SecurityGroups[*].IpPermissions[]'
  local found=false
  # Loop through groups and display permissions
  for group_id in "${group_ids[@]}"; do
    if [ "$filter_by_cidr" == true ]; then
      ip_permissions_query+=" | [?contains(IpRanges[].CidrIp, \`$search_cidr\`) || contains(Ipv6Ranges[].CidrIpv6, \`$search_cidr\`)]"
    fi
    local ip_permissions=$(aws ec2 describe-security-groups --group-ids "$group_id" --query "$ip_permissions_query" --output json --region "$region" 2>/dev/null)
    if [ "$ip_permissions" != "[]" ]; then
      found=true
      display_formatted_output "$ip_permissions" "$group_id" "$region"
    fi
  done

  if [ "$filter_by_cidr" == true ] && [ "$found" == false ]; then
    echo "The CIDR $search_cidr was not found in any Security Group in region $region."
  fi
  echo
}

# User prompts for input
read -p "Enter the AWS region (e.g., us-east-1), or press enter for all regions: " input_region
echo

filter_by_cidr=false
# Ask if the user wants to filter by CIDR
read -p "Do you want to search security groups for a specific CIDR? (y/N): " filter_cidr_answer
if [[ "$filter_cidr_answer" =~ ^[Yy](es)?$ ]]; then
    while true; do
        read -p "Enter the CIDR block you want to search for (e.g., 10.0.0.0/24): " input_cidr

        # Pattern matching both IPv4 and IPv6 CIDR notation
        ipv4_pattern='^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'
        ipv6_pattern='^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}(/[0-9]{1,3})?$'

        if [[ "$input_cidr" =~ $ipv4_pattern || "$input_cidr" =~ $ipv6_pattern ]]; then
            search_cidr="$input_cidr"
            filter_by_cidr=true
            break
        else
            echo "Invalid CIDR format. Please enter a valid CIDR block."
        fi
    done
else
    filter_by_cidr=false
fi

# Main execution
if [ -n "$input_region" ]; then
  if ! aws ec2 describe-regions --query 'Regions[].RegionName' --output text | grep -qw "$input_region"; then
    echo "The region '$input_region' is not valid."
    exit 1
  fi
  check_security_groups "$input_region"
else
  for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
    check_security_groups "$region"
  done
fi

# Fetch AWS account ID
account_id=$(aws sts get-caller-identity --query "Account" --output text)

# Get the current time
current_time=$(date +%Y-%m-%d\ %H:%M:%S)

# Display account ID and the time of script execution
echo "AWS Account ID: $account_id"
echo "Time of script execution: $current_time"

echo "Script execution completed."