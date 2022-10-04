/* Parameters */
param environmentName string
param location string = resourceGroup().location
param principalId string = ''
param uniqueIdentifierForResourcesName string = ''
param tags object
param serviceBusQueuesNames array = []

/* Resources */
// Azure Monitor
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    environmentName: environmentName
    location: location
    uniqueIdentifierForResourcesName: uniqueIdentifierForResourcesName
    tags: tags
  }
}

// Azure Key Vault
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    environmentName: environmentName
    location: location
    principalId: principalId
    uniqueIdentifierForResourcesName: uniqueIdentifierForResourcesName
    tags: tags
  }
}

// Service Bus
module serviceBus 'modules/servicebus-queues.bicep' = {
  name: 'serviceBus'
  params: {
    environmentName: environmentName
    location: location
    uniqueIdentifierForResourcesName: uniqueIdentifierForResourcesName
    tags: tags
    serviceBusQueuesNames: serviceBusQueuesNames
  }
}

// Variable configured post service bus deployment
var functionAppSettingsRegardingServiceBus = [
  {
    name: 'ServiceBusConnection__fullyQualifiedNamespace'
    value: serviceBus.outputs.serviceBusNamespaceFullQualifiedName
  }
]

// Function App
module functionApp 'modules/functionapp-dotnet.bicep' = {
  name: 'functionApp'
  params: {
    environmentName: environmentName
    location: location
    uniqueIdentifierForResourcesName: uniqueIdentifierForResourcesName
    tags: tags
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    functionAppAdditionalAppSettings: functionAppSettingsRegardingServiceBus
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

// Function App access to Key Vault
module functionAppAccessToKeyVault 'modules/keyvault-access.bicep' = {
  name: 'functionAppAccessToKeyVault'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    principalId: functionApp.outputs.functionAppManagedIdentityId
  }
}

// Function App access to Service Bus
module functionAppAccessToServiceBus 'modules/servicebus-access.bicep' = {
  name: 'functionAppAccessToServiceBus'
  params: {
    serviceBusNamespaceName: serviceBus.outputs.serviceBusNamespaceName
    principalId: functionApp.outputs.functionAppManagedIdentityId
  }
}

/* Outputs */
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.keyVaultEndpoint
