@description('Basename / Prefix of all resources')
param baseName string

@description('Azure Location/Region')
param location string 

@description('Id of the Container Apps Environment')
param containerAppsEnvironmentId string

@description('Workload Profile Name (optional)')
param workloadProfileName string = ''

var nginxConf = loadTextContent('nginx-default.conf')

resource nginx 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${baseName}-nginx-app'
  location: location
  properties: {
    environmentId: containerAppsEnvironmentId
    configuration: {
      secrets: [
        {
          name: 'nginx-conf'
          value: nginxConf
        }
      ]
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'nginx'
          image: 'nginx:latest'
          volumeMounts: [
            {
              mountPath: '/etc/nginx/conf.d/'
              volumeName: 'nginx-conf'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
      volumes: [
        {
          name: 'nginx-conf'
          storageType: 'Secret'
          secrets: [
            {
              secretRef: 'nginx-conf'
              path: 'default.conf'
            }
          ]
        }
      ]
    }
    workloadProfileName: workloadProfileName
  }
}

resource containerApp1 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'hello-container-app-v1'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: false
        targetPort: 3000
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: 'sebafo/hello-container-app:v1'
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
        maxReplicas: 1
      }
    }
    workloadProfileName: workloadProfileName
  }
}

resource containerApp2 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'hello-container-app-v2'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      ingress: {
        external: false
        targetPort: 3000
        transport: 'http'
      }
    }
    template: {
      containers: [
        {
          name: 'app'
          image: 'sebafo/hello-container-app:v2'
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
        maxReplicas: 1
      }
    }
    workloadProfileName: workloadProfileName
  }
}

output containerFqdn string = 'https://${nginx.properties.configuration.ingress.fqdn}'
output azAppLogs string = 'az containerapp logs show -n ${nginx.name} -g ${resourceGroup().name} --revision ${nginx.properties.latestRevisionName} --follow --tail 30'
