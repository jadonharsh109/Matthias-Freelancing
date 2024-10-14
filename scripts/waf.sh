#!/bin/bash

# Check if AWS CLI and jq are installed
if ! command -v aws &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: This script requires both AWS CLI and jq to be installed." >&2
    exit 1
fi

# Ask the user for the scope
read -p "Enter the scope (CLOUDFRONT or REGIONAL): " SCOPE
SCOPE="${SCOPE^^}"  # Convert to uppercase to match AWS CLI expected input

# Validate SCOPE input
if [ "$SCOPE" != "CLOUDFRONT" ] && [ "$SCOPE" != "REGIONAL" ]; then
    echo "Error: Invalid scope. Please enter 'CLOUDFRONT' or 'REGIONAL'." >&2
    exit 1
fi

# List all web ACLs and handle errors
if ! WEB_ACL_LIST=$(aws wafv2 list-web-acls --scope ${SCOPE} 2> /dev/null); then
    echo "Error listing Web ACLs: Make sure you have the right permissions and AWS CLI is configured correctly." >&2
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
    if ! WEB_ACL_DETAILS=$(aws wafv2 get-web-acl --name "${WEB_ACL_NAME}" --scope ${SCOPE} --id ${WEB_ACL_ID} 2> /dev/null); then
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
        if ! IP_SET_DETAILS=$(aws wafv2 get-ip-set --scope ${SCOPE} --id ${IP_SET_ID} --name "${IP_SET_NAME}" 2> /dev/null); then
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
