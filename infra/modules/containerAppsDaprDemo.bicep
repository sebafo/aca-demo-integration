param location string
param environmentName string
param baseName string
param managedIdentityName string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

resource environment 'Microsoft.App/managedEnvironments@2022-11-01-preview' existing = {
  name: environmentName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' existing = {
  name: managedIdentityName
}

module storage './storageAccount.bicep' = {
  name: 'storage'
  params: {
    location: location
    baseName: baseName
    managedIdentityName: managedIdentity.name
  }
}

// Dapr state store component 
resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: 'statestore'
  parent: environment
  properties: {
    componentType: 'state.azure.blobstorage'
    version: 'v1'
    ignoreErrors: false
    initTimeout: '5s'
    metadata: [
      {
        name: 'accountName'
        value: storage.outputs.storageAccountName
      }
      {
        name: 'containerName'
        value: storage.outputs.blobContainerName
      }
      {
        name: 'azureClientId'
        value: managedIdentity.properties.clientId
      }
    ]
    scopes: [
      'nodeapp'
    ]
  }
}


resource nodeapp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'nodeapp'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}' : {}
    }
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 3000
      }
      dapr: {
        enabled: true
        appId: 'nodeapp'
        appProtocol: 'http'
        appPort: 3000
      }
    }
    template: {
      containers: [
        {
          image: 'dapriosamples/hello-k8s-node:latest'
          name: 'hello-k8s-node'
          env: [
            {
              name: 'APP_PORT'
              value: '3000'
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
    workloadProfileName: workloadProfileName
  }
  dependsOn: [
    daprComponent
  ]
}

resource pythonapp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'pythonapp'
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      dapr: {
        enabled: true
        appId: 'pythonapp'
      }
    }
    template: {
      containers: [
        {
          image: 'dapriosamples/hello-k8s-python:latest'
          name: 'hello-k8s-python'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
    workloadProfileName: workloadProfileName
  }
  dependsOn: [
    nodeapp
  ]
}
