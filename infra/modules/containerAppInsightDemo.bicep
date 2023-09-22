@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Id of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Id of the Log Analytics Workspace')
param logAnalyticsWorkspaceId string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

module applicationInsights 'appInsights.bicep' = {
  name: '${baseName}-appInsights'
  params: {
    baseName: baseName
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module albumApi 'containerApp.bicep' = {
  name: '${baseName}-album-api'
  params: {
    baseName: baseName
    location: location
    name: 'album-api'
    containerAppsEnvironmentId: containerAppsEnvironmentId
    containerImage: 'sebafo/album-api:v1'
    appIngress: true
    appIngressTargetPort: 3500
    appEnvs: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.outputs.appInsightsConnectionString
      }
    ]
    appProbes: []
    workloadProfileName: workloadProfileName
  }
}

module albumUi 'containerApp.bicep' = {
  name: '${baseName}-album-ui'
  params: {
    baseName: baseName
    location: location
    name: 'album-ui'
    containerAppsEnvironmentId: containerAppsEnvironmentId
    containerImage: 'sebafo/album-ui:v1'
    appIngressExternal: true
    appIngressTargetPort: 3000
    appEnvs: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.outputs.appInsightsConnectionString
      }
      {
        name: 'API_BASE_URL'
        value: 'http://${albumApi.outputs.containerAppName}'
      }
    ]
    appProbes: []
    workloadProfileName: workloadProfileName
  }
}

output demoFqdn string = albumUi.outputs.containerFqdn
