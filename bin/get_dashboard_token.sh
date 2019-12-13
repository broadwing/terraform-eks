#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract "foo" and "baz" arguments from the input into
# FOO and BAZ shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "KUBECONFIG=\(.kubeconfig)"')"

SECRET_ID=$(kubectl --kubeconfig=$KUBECONFIG -n kube-system get secret | grep eks-admin | awk '{print $1}')
TOKEN=$(kubectl --kubeconfig=$KUBECONFIG -n kube-system get secret -o json $SECRET_ID | jq -r .data.token | base64 -d)

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg secret_id "$SECRET_ID" --arg token "$TOKEN"  '{"token":$token, "secret_id":$secret_id}'
