#!/bin/sh
set -e

######################################
## Define Variables _ UPDATE VALUES
BASE_NAME="<your base name>"
LOCATION="northeurope"
TYPE="default" # none | appgw | frontdoor | default
######################################

## Resource Group & Deployment
RESOURCE_GROUP_NAME=$BASE_NAME-rg
DEPLOYMENT_NAME=$BASE_NAME-deployment-$(date +%s)
PARAMETER_FILE="parameters.$TYPE.json"

## Register Providers (if not done already)
az provider register --wait --namespace Microsoft.App
az provider register --wait --namespace Microsoft.ContainerService
az provider register --wait --namespace Microsoft.Cdn

## Create Resource Group if it doesn't exist
if [ $(az group exists --name $RESOURCE_GROUP_NAME) = false ]; then
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
fi

## Deploy Template
RESULT=$(az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file main.bicep \
    --parameters baseName=$BASE_NAME  \
    --parameters @$PARAMETER_FILE \
    --query properties.outputs.result)

## Output Result
# if type = frontdoor
if [ "$TYPE" = "frontdoor" ]; then
    PRIVATE_LINK_ENDPOINT_CONNECTION_ID=$(echo $RESULT | jq -r '.value.privateLinkEndpointConnectionId')
    PRIVATE_LINK_SERVICE_ID=$(echo $RESULT | jq -r '.value.privateLinkServiceId')

    ## Approve Private Link Service
    echo "Private link endpoint connection ID: $PRIVATE_LINK_ENDPOINT_CONNECTION_ID"
    az network private-endpoint-connection approve --id $PRIVATE_LINK_ENDPOINT_CONNECTION_ID --description "(Frontdoor) Approved by CI/CD"
    FQDN=$(echo $RESULT | jq -r '.value.fqdn')

    echo "...Deployment FINISHED!"
    echo "Please wait a few minutes until endpoint is established..."
    echo "--- FrontDoor FQDN: https://$FQDN ---"
fi
