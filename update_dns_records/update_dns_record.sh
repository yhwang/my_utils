#!/bin/bash

IBM_CLOUD_KEY=$(echo "$1" | jq -r '.IBM_CLOUD_KEY')
IBM_REGION=$(echo "$1" | jq -r '.IBM_REGION')
IBM_ORG=$(echo "$1" | jq -r '.IBM_ORG')
IBM_SPACE=$(echo "$1" | jq -r '.IBM_SPACE')
IBM_GROUP=$(echo "$1" | jq -r '.IBM_GROUP')
AWS_KEY_ID=$(echo "$1" | jq -r '.AWS_KEY_ID')
AWS_KEY=$(echo "$1" | jq -r '.AWS_KEY')
AWS_REGION=$(echo "$1" | jq -r '.AWS_REGION')
NETWORK_ID=$(echo "$1" | jq -r '.NETWORK_ID')
DNS_RECORD_ID=$(echo "$1" | jq -r '.DNS_RECORD_ID')

VARS=("IBM_CLOUD_KEY" "IBM_REGION" "IBM_ORG" "IBM_SPACE" "IBM_GROUP" "AWS_KEY_ID" "AWS_KEY" "AWS_REGION" "NETWORK_ID" "DNS_RECORD_ID")
for i in "${VARS[@]}"; do
    if [[ -z "${!i}" ]]; then
        echo "{\"message\": \"No ${i} var\"}"
        exit 1
    fi
done

## Login IBM Cloud
ibmcloud login --apikey "$IBM_CLOUD_KEY" --no-region
ibmcloud target -r "$IBM_REGION" -o "$IBM_ORG" -s "$IBM_SPACE" -g "$IBM_GROUP"

## Configure AWS
AWS_PROFILE=$(cat << EOF
[default]
aws_access_key_id=${AWS_KEY_ID}
aws_secret_access_key=${AWS_KEY}
EOF
)

AWS_CONF=$(cat <<EOF
[default]
region=${AWS_REGION}
EOF
)

mkdir -p ~/.aws
echo "$AWS_PROFILE" > ~/.aws/credentials
echo "$AWS_CONF" > ~/.aws/config

IP_ADDR=$(aws ec2 describe-network-interfaces --no-paginate | jq -r '[.NetworkInterfaces[]|select(.Description|startswith("'"$NETWORK_ID"'"))]|.[0].Association.PublicIp')

if [[ "$IP_ADDR" == "" ]]; then
    echo "{\"message\": \"Can not obtain IP address of ALB ingress\"}"
    exit 1
fi

CUR_IP_ADDR=$(ibmcloud sl dns record-list ml-exchange.org --output JSON | jq -r ".[]|select(.id==${DNS_RECORD_ID})|.data")

echo "CURRENT DNS IP: $CUR_IP_ADDR"

if [[ "$CUR_IP_ADDR" == "" ]]; then
    echo "{ \"message\": \"Can not obtain DNS Record\"}"
    exit 1
fi

if [[ "$CUR_IP_ADDR" != "$IP_ADDR" ]]; then
    echo "{\"message\": \"update DNS record to $IP_ADDR\"}"
    ibmcloud sl dns record-edit ml-exchange.org --by-id "$DNS_RECORD_ID" --ttl 86400 --data "$IP_ADDR"
else
    echo "{\"message\": \"no change\"}"
fi
