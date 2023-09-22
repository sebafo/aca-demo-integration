@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

@description('Subnet resource ID for the Container App environment')
param infrastructureSubnetId string

@description('Name of the log analytics workspace')
param logAnalyticsWorkspaceName string = '${baseName}-log'

@description('Internal only (no public IP)')
param internalOnly bool = false

@description('Workload Profile Name (optional)')
@maxLength(16)
param workloadProfileName string = ''

@description('Tags (optional)')
param tags object = {}

// Define names
var environmentName = '${baseName}-aca'

// Read Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Container Apps Environment
resource environment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  tags: union(tags, {
    name: environmentName
  })
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: infrastructureSubnetId
      internal: internalOnly
    }
    workloadProfiles: (workloadProfileName != '') ? [
      {
        maximumCount: 1
        minimumCount: 0
        name: workloadProfileName
        workloadProfileType: 'D4'
      }
    ] : []
    zoneRedundant: true
  }
}

output containerAppsEnvironmentName string = environment.name
output containerAppsEnvironmentId string = environment.id
output containerAppsEnvironmentStaticIp string = environment.properties.staticIp
output containerAppsEnvironmentDefaultDomain string = environment.properties.defaultDomain
