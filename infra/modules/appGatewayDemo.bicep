@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Basename / Prefix of all resources')
@minLength(4)
@maxLength(12)
param baseName string

@description('VNet Name to add GW Subnet to')
param vnetName string

param gwSubnetId string

@description('Container Apps Default Domain (DNS Zone)')
param containerAppsDefaultDomain string

@description('Container Apps Static IP (A Record)')
param containerAppsStaticIp string

@description('Container Apps URL (App Gateway Backend Address)')
param containerAppUrl string

// TLS Certificate
@description('TLS Certificate Key Vault Name')
param certificateKeyVaultName string = ''

@description('TLS Certificate Key Vault Resource Group')
param certificateKeyVaultResourceGroup string = ''

@description('TLS Certificate Secret Id')
@secure()
param certificateSecretId string = ''

// Read resources
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${baseName}-ip'
  location: location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: baseName
    }
  }
}

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: containerAppsDefaultDomain
  location: 'global'
}

resource containerAppsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: containerAppsStaticIp
      }
    ]
  }
}

resource containerAppsRecord2 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '@'
  parent: privateDnsZone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: containerAppsStaticIp
      }
    ]
  }
}

// Link Private DNS Zone to Vnet
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${baseName}-vnet-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Create Managed Identity for AppGateway to access KeyVault
resource appGwId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${baseName}-gw-id'
  location: location
}

module kvAccess 'certificateKvAccess.bicep' = {
  scope: resourceGroup(certificateKeyVaultResourceGroup)
  name: 'kvAccess'
  params: {
    certificateKeyVaultName: certificateKeyVaultName
    //location: location
    appGwId: appGwId.id
    appGwIdPrincipalId: appGwId.properties.principalId
  }
}

// Create Application Gateway
var appGwName = '${baseName}-gw'
var certificateName = '${baseName}-gw-cert'

resource appGw 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: appGwName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGwId.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          subnet: {
            id: gwSubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: certificateName
        properties: {
          keyVaultSecretId: certificateSecretId
        }
      }
    ]
    trustedRootCertificates: []
    trustedClientCertificates: []
    sslProfiles: []
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'appGatewayHttpsFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: containerAppUrl
            }
          ]
        }
      }
    ]
    loadDistributionPolicies: []
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpsSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          connectionDraining: {
            enabled: false
            drainTimeoutInSec: 1
          }
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGatewayFrontendIP') 
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
      {
        name: 'appGatewayHttpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGatewayFrontendIP') 
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'appGatewayHttpsFrontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGwName, '${certificateName}')
          }
          hostNames: []
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'ruleHttps'
        properties: {
          ruleType: 'Basic'
          priority: 99
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'appGatewayHttpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id:resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'appGatewayBackendHttpsSettings')
          }
        }
      }
      {
        name: 'ruleHttp'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'appGatewayHttpListener')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', appGwName, 'redirectHttpToHttps')
          }
        }
      }
    ]
    probes: []
    rewriteRuleSets: []
    redirectConfigurations: [
      {
        name: 'redirectHttpToHttps'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'appGatewayHttpsListener')
          }
          targetUrl: null
          includePath: true
          includeQueryString: true
        }
      }
    ]
    privateLinkConfigurations: []
  }
}

output publicFacingIp string = pip.properties.ipAddress
