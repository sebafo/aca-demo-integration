@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

param useWorkloadProfiles bool = false

param enableExtendedNetwork bool = false

// Define names
var vnetName = '${baseName}-vnet'

module simpleNetwork 'networkSimple.bicep' = if (!enableExtendedNetwork) {
  name: 'simpleNetwork'
  params: {
    baseName: baseName
    location: location
    vnetName: vnetName
    useWorkloadProfiles: useWorkloadProfiles
  }
}

module extendedNetwork 'networkExtended.bicep' = if (enableExtendedNetwork) {
  name: 'extendedNetwork'
  params: {
    baseName: baseName
    location: location
    vnetName: vnetName
    useWorkloadProfiles: useWorkloadProfiles
  }
}

output vnetid string = (enableExtendedNetwork) ? extendedNetwork.outputs.vnetid : simpleNetwork.outputs.vnetid
output vnetName string = (enableExtendedNetwork) ? extendedNetwork.outputs.vnetName : simpleNetwork.outputs.vnetid
output containerappsSubnetid string = (enableExtendedNetwork) ? extendedNetwork.outputs.containerappsSubnetid : simpleNetwork.outputs.vnetid
output gatewaySubnetid string = (enableExtendedNetwork) ? extendedNetwork.outputs.gwSubnetId : ''
