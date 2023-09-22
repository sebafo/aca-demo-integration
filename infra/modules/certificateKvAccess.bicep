@description('App Gateway Managed Identity Id')
param appGwId string

@description('App Gateway Managed Identity Principal Id')
param appGwIdPrincipalId string

@description('Key Vault Name')
param certificateKeyVaultName string

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: certificateKeyVaultName
}

var keyVaultSecretsUserRole = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
resource kvAppGwSecretsUserRole 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: kv
  name: guid(appGwId, kv.id, keyVaultSecretsUserRole)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
    principalId: appGwIdPrincipalId
  }
}

module rbacPropagationDelay 'br/public:deployment-scripts/wait:1.1.1' = {
  name: 'DeploymentDelay'
  dependsOn: [
    kvAppGwSecretsUserRole
  ]
  params: {
    waitSeconds: 60
  }
}

output certificateKeyVaultId string = kv.id
output certificateKeyVaultUri string = kv.properties.vaultUri
