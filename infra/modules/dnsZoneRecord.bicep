// Add Public Facing IP to DNS Zone
@description('DNS Zone Name')
param dnsZoneName string = ''

@description('DNS Zone Record Name')
param dnsZoneRecordName string = ''

@description('DNS Zone Record Value')
param dnsZoneRecordValue string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName
}

resource dnsRecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: dnsZoneRecordName
  parent: dnsZone
  properties: {
    TTL: 300
    ARecords: [
      {
        ipv4Address: dnsZoneRecordValue
      }
    ]
  }
}

output fqdn string = dnsRecord.properties.fqdn
