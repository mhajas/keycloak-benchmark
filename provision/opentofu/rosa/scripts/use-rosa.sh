#!/bin/bash

export CLUSTER_NAME=${1:-"gh-keycloak"}
CONFIGS_PATH=${3:-"$HOME/.kube"}

CLUSTER_ID=$(rosa describe cluster -c ${CLUSTER_NAME} -o json | jq -r .id)
export KUBECONFIG="$CONFIGS_PATH/$CLUSTER_NAME-$CLUSTER_ID-cfg"
API_URL=$(rosa describe cluster -c "$CLUSTER_NAME" -o json | jq -r '.api.url')

if [[ ! -f "$KUBECONFIG" ]]
then
  ADMIN_PASSWORD=${2:-$(aws secretsmanager get-secret-value --region "eu-central-1" --secret-id "keycloak-master-password" --query SecretString --output text --no-cli-pager)}
  KUBECONFIG=$KUBECONFIG oc login $API_URL --username cluster-admin --password $ADMIN_PASSWORD --insecure-skip-tls-verify > /dev/null 2> /dev/null
fi

echo "{\"kubeconfig\": \"$KUBECONFIG\", \"api_url\": \"$API_URL\"}"


