@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
param baseName string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

// Demo parts
param featureHelloWorld bool = true
param featureNginxDemo bool = false
param featureDaprDemo bool = false
param featureApplicationInsightsDemo bool = false
param featureFrontDoorDemo bool = false
param featureAppGatewayDemo bool = false
param featureIsolatedDemo bool = false

// Add Public Facing IP to DNZ Zone
@description('DNS Zone Name')
param dnsZoneName string = ''

@description('DNS Zone Resource Group')
param dnsZoneResourceGroup string = ''

@description('DNS Zone Record Name')
param dnsZoneRecordName string = ''

// TLS Certificate
@description('TLS Certificate Key Vault Name')
param certificateKeyVaultName string = ''

@description('TLS Certificate Key Vault Resource Group')
param certificateKeyVaultResourceGroup string = ''

@description('TLS Certificate Secret Id')
@secure()
param certificateSecretId string = ''

@description('Custom Tags')
param customTags object = {}

var tags = union(
  {
    identifier: baseName
    source: 'Bicep'
    location: location
  },
  customTags
)

var addDnsZoneRecord = (dnsZoneName != '') ? true : false

module network './modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    baseName: baseName
    useWorkloadProfiles: workloadProfileName != '' ? true : false
    enableExtendedNetwork: (featureAppGatewayDemo) ? true : false
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    baseName: baseName
  }
}

module containerAppsEnv './modules/containerAppsEnv.bicep' = {
  name: 'containerappEnv'
  params: {
    location: location
    baseName: baseName
    logAnalyticsWorkspaceName: logAnalytics.outputs.logAnalyticsWorkspaceName
    infrastructureSubnetId: network.outputs.containerappsSubnetid
    tags: tags
    workloadProfileName: (featureFrontDoorDemo && !featureAppGatewayDemo) ? '' : workloadProfileName // Front Door doesn't support workload profiles without AppGw
    internalOnly: (featureFrontDoorDemo || featureAppGatewayDemo || featureIsolatedDemo) ? true : false
  }
}

module appIdentity './modules/managedIdentity.bicep' = {
  name: 'appIdentity'
  params: {
    location: location
    baseName: baseName
  }
}

module daprDemo './modules/containerAppsDaprDemo.bicep' = if (featureDaprDemo) {
  name: 'daprDemo'
  params: {
    baseName: baseName
    location: location
    environmentName: containerAppsEnv.outputs.containerAppsEnvironmentName
    managedIdentityName: appIdentity.outputs.managedIdentityName
    workloadProfileName: workloadProfileName
  }
}

module helloWorldcontainerApp './modules/containerAppHelloWorld.bicep' = if (featureHelloWorld) {
  name: 'containerApp'
  params: {
    location: location
    baseName: baseName
    containerAppsEnvironmentId: containerAppsEnv.outputs.containerAppsEnvironmentId
    containerImage: 'sebafo/containerapp:v1'
    workloadProfileName: workloadProfileName
  }
}

module nginx './modules/containerAppNginx.bicep' = if (featureNginxDemo) {
  name: 'nginx'
  params: {
    baseName: baseName
    containerAppsEnvironmentId: containerAppsEnv.outputs.containerAppsEnvironmentId
    location: location
    workloadProfileName: workloadProfileName
  }
}

module appInsightsDemo 'modules/containerAppInsightDemo.bicep' = if (featureApplicationInsightsDemo) {
  name: 'appInsightsDemo'
  params: {
    baseName: baseName
    location: location
    containerAppsEnvironmentId:  containerAppsEnv.outputs.containerAppsEnvironmentId
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    workloadProfileName: workloadProfileName
  }
}

module frontDoorDemo 'modules/frontDoorDemo.bicep' = if (featureFrontDoorDemo) {
  name: 'frontDoorDemo'
  params: {
    baseName: baseName
    location: location
    containerAppsDefaultDomainName: containerAppsEnv.outputs.containerAppsEnvironmentDefaultDomain
    containerAppsFqdn: helloWorldcontainerApp.outputs.containerFqdn
    subnetId: network.outputs.containerappsSubnetid
  }
}

output result object = (featureFrontDoorDemo) ? {
  fqdn: frontDoorDemo.outputs.frontdoorFqdn
  privateLinkServiceId: frontDoorDemo.outputs.result
  privateLinkEndpointConnectionId: frontDoorDemo.outputs.privateLinkEndpointConnectionId
} : {}

module appGw 'modules/appGatewayDemo.bicep' = if (featureAppGatewayDemo) {
  name: 'appGateway'
  params: {
    baseName: baseName 
    location: location
    vnetName: network.outputs.vnetName
    containerAppsDefaultDomain: containerAppsEnv.outputs.containerAppsEnvironmentDefaultDomain
    containerAppsStaticIp: containerAppsEnv.outputs.containerAppsEnvironmentStaticIp
    containerAppUrl: helloWorldcontainerApp.outputs.containerFqdn
    certificateKeyVaultName: certificateKeyVaultName
    certificateKeyVaultResourceGroup: certificateKeyVaultResourceGroup
    certificateSecretId: certificateSecretId
    gwSubnetId: network.outputs.gatewaySubnetid
  }
}

// Add DNS Zone Record for Public Facing IP
var dnsZoneRecordValue = (featureAppGatewayDemo) ? appGw.outputs.publicFacingIp : ''
// Use Basename as DNS Zone Name if not specified. Remove everything before the first - (if any)
var dnsZoneResourceGroupV = (length(dnsZoneResourceGroup) > 0) ? dnsZoneResourceGroup : certificateKeyVaultResourceGroup

module dnsZoneRecord 'modules/dnsZoneRecord.bicep' = if (addDnsZoneRecord) {
  scope: resourceGroup(dnsZoneResourceGroupV)
  name: 'dnsZoneRecord'
  params: {
    dnsZoneName: dnsZoneName
    dnsZoneRecordName: (dnsZoneRecordName != '') ? dnsZoneRecordName : baseName
    dnsZoneRecordValue: dnsZoneRecordValue
  }
}

output fqdn string = (addDnsZoneRecord) ? dnsZoneRecord.outputs.fqdn : (featureFrontDoorDemo) ? frontDoorDemo.outputs.frontdoorFqdn : helloWorldcontainerApp.outputs.containerFqdn
