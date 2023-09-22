@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

param logAnalyticsWorkspaceId string

// Define names
var appInsightsName = '${baseName}-ai'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
