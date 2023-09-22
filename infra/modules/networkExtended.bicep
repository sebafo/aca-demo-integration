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

resource gwNsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${baseName}-gw-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Gateway'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      // Allow HTTP 80 inbound
      {
        name: 'HTTP'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 101
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      // Allow HTTPS 443 inbound
      {
        name: 'HTTPS'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      // Allow all internet outbound
      {
        name: 'Internet'
        type: 'Microsoft.Network/networkSecurityGroups/securityRules'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 102
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
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
      {
        name: '${baseName}-gw-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: gwNsg.id
          }
        }
      }
    ]
  }

  resource containerappsSubnet 'subnets' existing = {
    name: 'containerapp-snet'
  }
  resource gwSubnet 'subnets' existing = {
    name: '${baseName}-gw-subnet'
  }
}

output vnetid string = vnet.id
output vnetName string = vnet.name
output containerappsSubnetid string = vnet::containerappsSubnet.id
output gwSubnetId string = vnet::gwSubnet.id
