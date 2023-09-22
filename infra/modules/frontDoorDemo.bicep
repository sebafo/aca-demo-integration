@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
param baseName string

param subnetId string

param containerAppsDefaultDomainName string

param containerAppsFqdn string

module privateLinkService './privateLinkService.bicep' = {
  name: 'privatelink'
  params: {
    location: location
    baseName: baseName
    vnetSubnetId: subnetId
    containerAppsDefaultDomainName: containerAppsDefaultDomainName
  }
}

module frontDoor './frontdoor.bicep' = {
  name: 'frontdoor'
  params: {
    baseName: baseName
    location: location
    privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
    frontDoorAppHostName: containerAppsFqdn
  }
}

// Re-Read Private Link Service to get Pending Approval status
module readPrivateLinkService './readPrivateEndpoint.bicep' = {
  name: 'readprivatelink'
  params: {
    privateLinkServiceName: privateLinkService.outputs.privateLinkServiceName
  }

  dependsOn: [
    frontDoor
  ]
}

// Prepare Output
var privateLinkEndpointConnectionId = readPrivateLinkService.outputs.privateLinkEndpointConnectionId
var fqdn = frontDoor.outputs.fqdn

// Outputs
output frontdoorFqdn string = fqdn
output privateLinkEndpointConnectionId string = privateLinkEndpointConnectionId
output privateLinkServiceId string = privateLinkService.outputs.privateLinkServiceId

output result object = {
  fqdn: fqdn
  privateLinkServiceId: privateLinkService.outputs.privateLinkServiceId
  privateLinkEndpointConnectionId: privateLinkEndpointConnectionId
}
