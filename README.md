# ACA Integration

## Overview
This project deploys ACA components. The idea is to have a single main module that can be used to deploy the ACA integration components in a single command. The project will deploy the following components:

- Azure Container Apps (Environment, Apps)
- Virtual Network
- Network Security Group
- Azure Front Door (optional)
- Application Gateway (optional)
    - Frontend IP
    - Private DNS Zone
    - Managed Identity
- Lockdown (with limited egress traffic) (coming soon...)

The project will also deploy the following optional resources:
- Storage Account
- Application Insights


## Prerequisites

Azure Subscription + Registered Providers:
- Microsoft.App
- Microsoft.ContainerService
- Microsoft.Cdn (for FrontDoor)


## Deployment

Run the following command to deploy the ACA integration components:

```bash
az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file main.bicep \
    --parameters baseName=$BASE_NAME  \
    --parameters @$PARAMETER_FILE \
    --query properties.outputs.result)
```
You can set the baseName parameter to a prefix of your choice. The deployment will append suffixes to the baseName.

To ease the deployment, you can use the scripts stored in /infra. The scripts will create a resource group and deploy the ACA integration components into that resource group.

### Parameters

| ParameterName | Required | DefaultValue | Description |
| --- | --- | --- | --- |
| location | No | Resource group location | Azure location/region where the resources will be deployed |
| baseName | Yes | N/A | Basename/prefix of all resources |
| workloadProfileName | No | Empty string | Name of the workload profile to use |
| featureHelloWorld | No | `true` | Whether to include the "Hello World" demo feature. Required for FrontDoor or Application Gateway feature |
| featureNginxDemo | No | `false` | Whether to include the Nginx demo feature |
| featureDaprDemo | No | `false` | Whether to include the Dapr demo feature |
| featureApplicationInsightsDemo | No | `false` | Whether to include the Application Insights demo feature |
| featureFrontDoorDemo | No | `false` | Whether to include the Front Door demo feature |
| featureAppGatewayDemo | No | `false` | Whether to include the Application Gateway demo feature |
| featureIsolatedDemo | No | `false` | Whether to include the Isolated demo feature |
| dnsZoneName | No | Empty string | Name of the DNS zone to add a public facing IP to |
| dnsZoneResourceGroup | No | Empty string | Resource group of the DNS zone |
| dnsZoneRecordName | No | Empty string | Name of the DNS zone record |
| certificateKeyVaultName | No | Empty string | Name of the Key Vault that contains the TLS certificate, in a BYO certificate scenario |
| certificateKeyVaultResourceGroup | No | Empty string | Resource group of the Key Vault |
| certificateSecretId | No | Empty string | Secret ID of the TLS certificate |
| customTags | No | Empty object | Custom tags to apply to the resources |

### TODOs

- [ ] Add lockdown feature
- [ ] Include the output URL in the deployment output

