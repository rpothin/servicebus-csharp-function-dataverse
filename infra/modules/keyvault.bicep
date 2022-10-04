/* Parameters */
param environmentName string
param location string = resourceGroup().location
param principalId string = ''
param uniqueIdentifierForResourcesName string = ''
param tags object

/* Variables */
var abbreviations = loadJsonContent('../abbreviations.json')

/* Resources */
// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${abbreviations.keyVaultVaults}${environmentName}-${uniqueIdentifierForResourcesName}'
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

/* Outputs */
output keyVaultEndpoint string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
