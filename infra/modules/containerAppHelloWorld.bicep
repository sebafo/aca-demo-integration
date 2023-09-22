@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

@description('Id of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Container Image')
param containerImage string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

// Define names
var appName = 'hello-world-app'

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${baseName}-${appName}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: containerImage
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 3000
              }
              periodSeconds: 10
              failureThreshold: 3
              initialDelaySeconds: 20
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
    workloadProfileName: workloadProfileName
  }
}

output containerFqdn string = containerApp.properties.configuration.ingress.fqdn
