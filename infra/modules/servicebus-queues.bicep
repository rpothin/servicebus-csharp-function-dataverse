/* Parameters */
param environmentName string
param location string = resourceGroup().location
param uniqueIdentifierForResourcesName string = ''
param tags object
param serviceBusQueuesNames array = []

/* Variables */
var abbreviations = loadJsonContent('../abbreviations.json')
var serviceBusName = '${abbreviations.serviceBusNamespaces}${environmentName}-${uniqueIdentifierForResourcesName}'

/* Resources */
// Service Bus Namespace
resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

// Service Bus Queues
resource serviceBusQueues 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = [for queueName in serviceBusQueuesNames: {
  parent: serviceBus
  name: queueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}]

/* Outputs */
output serviceBusNamespaceName string =  serviceBus.name
output serviceBusNamespaceFullQualifiedName string = '${serviceBus.name}.servicebus.windows.net'
