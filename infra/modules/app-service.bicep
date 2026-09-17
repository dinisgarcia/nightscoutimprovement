param location string
param tags object
param appServiceName string
param appServicePlanId string
param keyVaultName string
param appInsightsConnectionString string
param acrLoginServer string
param containerImage string
param managedIdentityResourceId string
param managedIdentityClientId string
param managedIdentityPrincipalId string
param virtualNetworkSubnetId string

resource appService 'Microsoft.Web/sites@2024-11-01' = {
  name: appServiceName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    keyVaultReferenceIdentity: managedIdentityResourceId
    virtualNetworkSubnetId: virtualNetworkSubnetId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImage}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      healthCheckPath: '/api/v1/status.json'
      vnetRouteAllEnabled: true
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '1337'
        }
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'ENABLE'
          value: 'careportal basal dbsize rawbg iob cob bwp cage iage sage boluscalc profile food treatmentnotify ar2'
        }
        {
          name: 'INSECURE_USE_HTTP'
          value: 'false'
        }
        {
          name: 'NIGHTSCOUT_HOSTNAME'
          value: '0.0.0.0'
        }
        {
          name: 'MONGO_CONNECTION'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=mongodb-uri)'
        }
        {
          name: 'API_SECRET'
          value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=api-secret)'
        }
        {
          name: 'AUTH_DEFAULT_ROLES'
          value: 'readable'
        }
        {
          name: 'NIGHT_MODE'
          value: 'on'
        }
        {
          name: 'THEME'
          value: 'default'
        }
        {
          name: 'SHOW_PLUGINS'
          value: 'delta direction timeago iob cob basal cage sage'
        }
        {
          name: 'SECURE_CSP'
          value: 'true'
        }
        {
          name: 'SECURE_CSP_REPORT_ONLY'
          value: 'false'
        }
        {
          name: 'ALLOW_UNRESTRICTED_FRAME_EMBEDDING'
          value: 'false'
        }
      ]
      connectionStrings: []
    }
  }
}

resource scmAuth 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: appService
  name: 'scm'
  properties: {
    allow: false
  }
}

// FTP basic auth — always disabled
resource ftpAuth 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2023-12-01' = {
  parent: appService
  name: 'ftp'
  properties: {
    allow: false
  }
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output principalId string = managedIdentityPrincipalId
output defaultHostName string = appService.properties.defaultHostName
