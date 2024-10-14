#!/bin/bash

# Function to display an error message
error() {
    echo "Error: $1" >&2
}

# Check if both AWS CLI and jq are installed
if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null; then
    error "This script requires both AWS CLI and jq to be installed."
    exit 1
fi

# Prompt user for action choice
read -p "Choose action - (1) List Web ACLs (2) Search CIDR in IP sets: " ACTION_CHOICE

case $ACTION_CHOICE in
    1)
        # Prompt user for scope choice
        echo "Select scope:"
        echo " 1) CloudFront"
        echo " 2) Regional"
        read -p "Enter choice [1-2]: " SCOPE

        REGION_FLAG=""
        case $SCOPE in
        1)
            SCOPE="CLOUDFRONT"
            REGION_FLAG="--region=us-east-1"
            ;;
        2)
            SCOPE="REGIONAL"
            # Prompt user for the region when scope is REGIONAL
            read -p "Enter the region name: " REGION
            if [[ -z $REGION ]]; then
                error "You must specify a region name."
                exit 1
            fi
            REGION_FLAG="--region=${REGION}"
            ;;
        *)
            error "Invalid scope choice. Please enter '1' for CloudFront or '2' for Regional."
            exit 1
            ;;
        esac

echo

# In the part of the script where the AWS CLI command may fail:
WEB_ACL_LIST=$(aws wafv2 $REGION_FLAG list-web-acls --scope=${SCOPE} 2>&1)
if [ $? -ne 0 ]; then
    error "Error listing Web ACLs: ${WEB_ACL_LIST}"
    exit 1
fi

WEB_ACL_COUNT=$(echo "${WEB_ACL_LIST}" | jq '.WebACLs | length')
if [ $? -ne 0 ]; then
    echo "Error parsing Web ACL list with jq." >&2
    exit 1
fi

# No Web ACLs found condition
if [ "${WEB_ACL_COUNT}" -eq "0" ]; then
    echo "No Web ACLs found."
    exit 0
fi

# Iterate through each Web ACL
for i in $(seq 0 $((${WEB_ACL_COUNT} - 1))); do
    WEB_ACL_ID=$(echo "${WEB_ACL_LIST}" | jq -r ".WebACLs[${i}].Id" 2> /dev/null) || continue
    WEB_ACL_NAME=$(echo "${WEB_ACL_LIST}" | jq -r ".WebACLs[${i}].Name" 2> /dev/null) || continue

    echo "Web ACL Name: $WEB_ACL_NAME, ID: $WEB_ACL_ID"

    # Fetch details and check for errors
    if ! WEB_ACL_DETAILS=$(aws wafv2 $REGION_FLAG get-web-acl --name "${WEB_ACL_NAME}" --scope=${SCOPE} --id ${WEB_ACL_ID} 2> /dev/null); then
        echo "Error getting details for Web ACL ${WEB_ACL_NAME}: ${WEB_ACL_ID}" >&2
        continue
    fi

    IP_SET_REFERENCES=$(echo "${WEB_ACL_DETAILS}" | jq -r '.WebACL.Rules[] | select(.Statement.IPSetReferenceStatement)' 2> /dev/null)

    if [ -z "${IP_SET_REFERENCES}" ]; then
        echo "No IP whitelist rule found for this Web ACL."
        continue
    fi

    # Process IP set references
    echo "Processing IP set references..."
    for RULE in $(echo "${IP_SET_REFERENCES}" | jq -c '.'); do
        IP_SET_ARN=$(echo $RULE | jq -r '.Statement.IPSetReferenceStatement.ARN' 2> /dev/null)
        IP_SET_ID=$(echo ${IP_SET_ARN} | cut -d '/' -f 4)
        IP_SET_NAME=$(echo ${IP_SET_ARN} | cut -d '/' -f 3)

        # Find the action (Allow/Block) for the IP set
        ACTION_TYPE=$(echo $RULE | jq -r '.Action | keys[]')

        # Fetch IP set details and check for errors
        if ! IP_SET_DETAILS=$(aws wafv2 $REGION_FLAG get-ip-set --scope=${SCOPE} --id ${IP_SET_ID} --name "${IP_SET_NAME}" 2> /dev/null); then
            echo "Error getting IP set details for ${IP_SET_NAME}: ${IP_SET_ID}" >&2
            continue
        fi
        
        IP_RANGES=$(echo "${IP_SET_DETAILS}" | jq -r '.IPSet.Addresses[]' 2> /dev/null)

        echo "IP Set Name: ${IP_SET_NAME}, ID: ${IP_SET_ID}, Action: ${ACTION_TYPE^}"

        if [ -z "${IP_RANGES}" ]; then
            echo "No IP ranges found for this IP set."
        else
            echo "${ACTION_TYPE^} IP ranges for ${IP_SET_NAME}:"
            echo "${IP_RANGES}"
        fi
        echo
    done
done

        ;;

    2)
    read -p "Enter the CIDR to search for (e.g., 192.168.1.0/24): " SEARCH_CIDR

        # Prompt user for scope choice and set REGION_FLAG if scope is CloudFront
        echo "Select scope:"
        echo " 1) CloudFront"
        echo " 2) Regional"
        read -p "Enter choice [1-2]: " SCOPE

        REGION_FLAG=""
        case $SCOPE in
        1)
            SCOPE="CLOUDFRONT"
            REGION_FLAG="--region=us-east-1"
            ;;
        2)
            SCOPE="REGIONAL"
            # Prompt user for the region when scope is REGIONAL
            read -p "Enter the region name: " REGION
            if [[ -z $REGION ]]; then
                error "You must specify a region name."
                exit 1
            fi
            REGION_FLAG="--region=${REGION}"
            ;;
        *)
            error "Invalid scope choice. Please enter '1' for CloudFront or '2' for Regional."
            exit 1
            ;;
        esac

echo

# Get the list of all web ACLs
WEB_ACL_LIST=$(aws wafv2 $REGION_FLAG list-web-acls --scope="${SCOPE}" --output json 2>&1)
if [ $? -ne 0 ]; then
    error "Failed to retrieve Web ACL list: $WEB_ACL_LIST"
    exit 1
fi

WEB_ACL_COUNT=$(echo "${WEB_ACL_LIST}" | jq '.WebACLs | length')

# Check if any ACLs are present
if [ "${WEB_ACL_COUNT}" -eq 0 ]; then
    echo "No Web ACLs found for the given scope."
    exit 0
fi

# Flag to check if CIDR is found
CIDR_FOUND=0

# Function to process IP set details
check_ip_set() {
    local ip_set_arn="$1"
    local rule_action="$2"

    IP_SET_ID=$(echo "${ip_set_arn}" | cut -d '/' -f 4)
    IP_SET_NAME=$(echo "${ip_set_arn}" | cut -d '/' -f 3)

    IP_SET_DETAILS=$(aws wafv2 $REGION_FLAG get-ip-set --scope="${SCOPE}" --id "${IP_SET_ID}" --name "${IP_SET_NAME}" --output json 2>&1)
    if [ $? -ne 0 ]; then
        error "Failed to retrieve IP set details: $IP_SET_DETAILS"
        return 1
    fi
    
    IP_RANGES=$(echo "${IP_SET_DETAILS}" | jq -r '.IPSet.Addresses[]')

    if echo "${IP_RANGES}" | grep -qw "${SEARCH_CIDR}"; then
        CIDR_FOUND=1
        echo "CIDR ${SEARCH_CIDR} found!!"
        echo "Web ACL ID: $WEB_ACL_ID"
        echo "IP Set Name: $IP_SET_NAME"
        echo "IP Set ID: $IP_SET_ID"
        echo "Action: ${rule_action^}"
        echo
    fi
}

# Iterate through each Web ACL
for i in $(seq 0 $((WEB_ACL_COUNT - 1))); do
    WEB_ACL_ID=$(echo "${WEB_ACL_LIST}" | jq -r ".WebACLs[${i}].Id")
    WEB_ACL_NAME=$(echo "${WEB_ACL_LIST}" | jq -r ".WebACLs[${i}].Name")
    WEB_ACL_DETAILS=$(aws wafv2 $REGION_FLAG get-web-acl --name "${WEB_ACL_NAME}" --scope="${SCOPE}" --id "${WEB_ACL_ID}" --output json 2>&1)
    if [ $? -ne 0 ]; then
        error "Failed to retrieve Web ACL details: $WEB_ACL_DETAILS"
        continue
    fi

    IP_SET_REFERENCES=$(echo "${WEB_ACL_DETAILS}" | jq -c '.WebACL.Rules[] | select(.Statement.IPSetReferenceStatement)')
    
    # Iterate over found IP sets
    for RULE in ${IP_SET_REFERENCES}; do
        IP_SET_ARN=$(echo $RULE | jq -r '.Statement.IPSetReferenceStatement.ARN')
        ACTION_TYPE=$(echo $RULE | jq -r '.Action | keys[]')

        check_ip_set "$IP_SET_ARN" "$ACTION_TYPE"
    done
done

# If CIDR was not found in any IP set
if [ "${CIDR_FOUND}" -eq "0" ]; then
    echo "CIDR ${SEARCH_CIDR} was not found in any WAF IP set."
fi

        ;;

    *)
        error "Invalid action choice. Please enter '1' or '2'."
        exit 1
        ;;
esac

# Fetch AWS account ID
account_id=$(aws sts get-caller-identity --query "Account" --output text)

# Get the current time
current_time=$(date +%Y-%m-%d\ %H:%M:%S)

# Display account ID and the time of script execution
echo "AWS Account ID: $account_id"
echo "Time of script execution: $current_time"

echo "Script execution completed."
