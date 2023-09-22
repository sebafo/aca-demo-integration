@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

// Define names
var managedIdentityName = '${baseName}-id'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: managedIdentityName
  location: location
}

output managedIdentityName string = managedIdentity.name
