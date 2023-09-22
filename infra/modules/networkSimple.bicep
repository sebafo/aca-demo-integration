@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

param useWorkloadProfiles bool = false

param vnetName string = '${baseName}-vnet'

// Define names
var subnetNsgName = '${baseName}-subnet-nsg'

// Create Network Security Group
resource subnetNsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: subnetNsgName
  location: location
  properties: {
    securityRules: [
    ]
  }
}

// Create VNET
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'containerapp-snet'
        properties: {
          addressPrefix: '10.0.0.0/23'
          networkSecurityGroup: {
            id: subnetNsg.id
          }
          privateLinkServiceNetworkPolicies: 'Disabled'
          delegations: useWorkloadProfiles ? [
            {
              name: 'ContainerApps'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ] : []
        }
      }
    ]
  }
}

output vnetid string = vnet.id
output vnetName string = vnet.name
output containerappsSubnetid string = vnet.properties.subnets[0].id
