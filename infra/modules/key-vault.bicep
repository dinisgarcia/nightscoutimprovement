param location string
param tags object
param keyVaultName string

@secure()
param mongoDbUri string

@secure()
param apiSecret string

resource keyVault 'Microsoft.KeyVault/vaults@2026-05-15' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// Store MongoDB URI as KV secret
resource mongoDbUriSecret 'Microsoft.KeyVault/vaults/secrets@2026-05-15' = {
  parent: keyVault
  name: 'mongodb-uri'
  properties: {
    value: mongoDbUri
  }
}

// Store API Secret as KV secret
resource apiSecretKvSecret 'Microsoft.KeyVault/vaults/secrets@2026-05-15' = {
  parent: keyVault
  name: 'api-secret'
  properties: {
    value: apiSecret
  }
}

output resourceId string = keyVault.id
output keyVaultName string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
