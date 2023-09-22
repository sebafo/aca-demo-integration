@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string = resourceGroup().location

@description('Id of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Name of the Container App')
param name string

@description('Container Image')
param containerImage string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

param appEnvs array = []
param appIngress bool = false
param appIngressExternal bool = false
param appIngressTargetPort int = 3000
param appProbes array = []

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${baseName}-${name}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: (appIngress || appIngressExternal) ? {
        external: appIngressExternal
        targetPort: appIngressTargetPort
      } : null
    }
    template: {
      containers: [
        {
          name: name
          image: containerImage
          env: appEnvs
          probes: appProbes
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
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
}

output containerAppName string = containerApp.name
output containerFqdn string = containerApp.properties.configuration.ingress.fqdn
