/* Parameters */
param serviceBusNamespaceName string
param principalId string

/* Variables */
var serviceBusRoleDefinitionsIds = [
  resourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0') // Service Bus Data Receiver
  resourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39') // Service Bus Data Sender
]

/* Existing resource */
resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' existing = {
  name: serviceBusNamespaceName
}

/* Resource */
resource serviceBusRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for serviceBusRoleDefinitionId in serviceBusRoleDefinitionsIds: {
  name: guid(serviceBusRoleDefinitionId, serviceBus.name, principalId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: serviceBusRoleDefinitionId
  }
}]
