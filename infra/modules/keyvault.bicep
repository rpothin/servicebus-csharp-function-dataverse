/* Parameters */
param environmentName string
param location string = resourceGroup().location
param principalId string = ''
param uniqueIdentifierForResourcesName string = ''
param tags object
param keyVaultSecretsDetails array = []

/* Variables */
var abbreviations = loadJsonContent('../abbreviations.json')

/* Resources */
// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbreviations.keyVaultVaults}${environmentName}-${substring(uniqueIdentifierForResourcesName, 0, 23 - length(abbreviations.keyVaultVaults) - length(environmentName))}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    accessPolicies: !empty(principalId) ? [
      {
        objectId: principalId
        permissions: { secrets: [ 'get', 'list', 'set' ] }
        tenantId: subscription().tenantId
      }
    ] : []
  }
}

// Key Vault Secrets
resource keyVaultSecrets 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = [for secret in keyVaultSecretsDetails: {
  parent: keyVault
  name: secret.name
  properties: {
    contentType: secret.contentType
    value: secret.value
  }
}]

/* Outputs */
output keyVaultEndpoint string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
