targetScope = 'subscription'

@minLength(1)
@maxLength(64)
param environmentName string

@minLength(1)
param location string

param sessionId string

param deployedBy string

param createdAt string

@secure()
param mongoDbUri string

@secure()
param apiSecret string

param deployerObjectId string

param containerImage string = 'nightscout/cgm-remote-monitor:15.0.8'

var tags = {
  'app-onboard-skill': 'true'
  'app-onboard-session-id': sessionId
  'created-at': createdAt
  environment: environmentName
  'deployed-by': deployedBy
}

// Reference to existing App Service Plan
var existingPlanResourceId = '/subscriptions/f13379e0-e089-4659-8f17-6e9f481a133e/resourceGroups/nightscoutdinis_group/providers/Microsoft.Web/serverfarms/ASP-nightscoutdinisgroup-bb74'

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-nightscout-prod-aeee'
  location: location
  tags: tags
}

module logAnalyticsModule 'modules/log-analytics.bicep' = {
  name: 'logAnalyticsModule'
  scope: rg
  params: {
    location: location
    tags: tags
    workspaceName: 'log-nightscout-prod-aeee'
  }
}

module appInsightsModule 'modules/app-insights.bicep' = {
  name: 'appInsightsModule'
  scope: rg
  params: {
    location: location
    tags: tags
    appInsightsName: 'appi-nightscout-prod-aeee'
    workspaceResourceId: logAnalyticsModule.outputs.workspaceId
  }
}

module identityModule 'modules/managed-identity.bicep' = {
  name: 'identityModule'
  scope: rg
  params: {
    location: location
    tags: tags
    identityName: 'id-nightscout-prod-aeee'
  }
}

module keyVaultModule 'modules/key-vault.bicep' = {
  name: 'keyVaultModule'
  scope: rg
  params: {
    location: location
    tags: tags
    keyVaultName: 'kv-nightscout-prod-aeee'
    mongoDbUri: mongoDbUri
    apiSecret: apiSecret
  }
}

module acrModule 'modules/container-registry.bicep' = {
  name: 'acrModule'
  scope: rg
  params: {
    location: location
    tags: tags
    registryName: 'crnightscoutprodaeee'
  }
}

module privateNetworkModule 'modules/private-network.bicep' = {
  name: 'privateNetworkModule'
  scope: rg
  params: {
    location: location
    tags: tags
    virtualNetworkName: 'vnet-nightscout-prod-aeee'
    appIntegrationSubnetName: 'snet-app-integration'
    privateEndpointSubnetName: 'snet-private-endpoints'
    keyVaultResourceId: keyVaultModule.outputs.resourceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

module appServiceModule 'modules/app-service.bicep' = {
  name: 'appServiceModule'
  scope: rg
  params: {
    location: location
    tags: tags
    appServiceName: 'nightscoutdinisgarcia2'
    appServicePlanId: existingPlanResourceId
    keyVaultName: keyVaultModule.outputs.keyVaultName
    appInsightsConnectionString: appInsightsModule.outputs.connectionString
    acrLoginServer: acrModule.outputs.loginServer
    containerImage: containerImage
    managedIdentityResourceId: identityModule.outputs.resourceId
    managedIdentityClientId: identityModule.outputs.clientId
    managedIdentityPrincipalId: identityModule.outputs.principalId
    virtualNetworkSubnetId: privateNetworkModule.outputs.appIntegrationSubnetId
  }
}

module roleAssignmentsModule 'modules/role-assignments.bicep' = {
  name: 'roleAssignmentsModule'
  scope: rg
  params: {
    keyVaultName: keyVaultModule.outputs.keyVaultName
    appServicePrincipalId: identityModule.outputs.principalId
    deployerObjectId: deployerObjectId
    acrName: acrModule.outputs.name
    appServicePrincipalType: 'ServicePrincipal'
  }
}

output resourceGroupName string = rg.name
output appServiceName string = appServiceModule.outputs.appServiceName
output keyVaultName string = keyVaultModule.outputs.keyVaultName
output containerRegistryLoginServer string = acrModule.outputs.loginServer
output virtualNetworkId string = privateNetworkModule.outputs.virtualNetworkId
output keyVaultPrivateEndpointId string = privateNetworkModule.outputs.privateEndpointId
