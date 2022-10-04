/* Parameters */
param environmentName string
param location string = resourceGroup().location
param uniqueIdentifierForResourcesName string = ''
param tags object
param applicationInsightsInstrumentationKey string
param functionAppAdditionalAppSettings array = []
param keyVaultName string

/* Variables */
var abbreviations = loadJsonContent('../abbreviations.json')
var storageAccountName = '${abbreviations.storageStorageAccounts}${environmentName}${uniqueIdentifierForResourcesName}'
var functionAppName = '${environmentName}app'
var functionAppCoreAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: applicationInsightsInstrumentationKey
  }
  {
    name: 'ENVIRONMENT-URL'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=environment-url)'
  }
  {
    name: 'CLIENT-ID'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=client-id)'
  }
  {
    name: 'CLIENT-SECRET'
    value: '@Microsoft.KeyVault(VaultName=${keyVaultName};SecretName=client-secret)'
  }
]
var functionAppAppSettings = length(functionAppAdditionalAppSettings) == 0 ? functionAppCoreAppSettings : concat(functionAppCoreAppSettings,functionAppAdditionalAppSettings)


/* Resources */
// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${abbreviations.webServerFarms}${uniqueIdentifierForResourcesName}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: functionAppAppSettings
      netFrameworkVersion: 'v6.0'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
  }
}

/* Outputs */
output functionAppManagedIdentityId string = functionApp.identity.principalId
