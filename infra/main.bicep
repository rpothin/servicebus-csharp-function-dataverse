/* Deployment scope */
targetScope = 'subscription'

/* Parameters */
@minLength(1)
@maxLength(50)
@description('Name of the the environment which is used to generate a short unique hash used in all resources')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign app roles')
param principalId string = ''

@description('Name of queues to configure in the service bus')
param serviceBusQueuesNames array = []

/* Variables */
var abbreviations = loadJsonContent('./abbreviations.json')
var uniqueIdentifierForResourcesName = toLower(uniqueString(subscription().id, '${environmentName}', location))
var tags = {
    'azd-env-name': environmentName
}

/* Resource group */
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
    name: '${abbreviations.resourcesResourceGroups}${environmentName}'
    location: location
    tags: tags
}

/* Resources */
module resources './resources.bicep' = {
    name: 'resources-${uniqueIdentifierForResourcesName}'
    scope: resourceGroup
    params: {
        environmentName: environmentName
        location: location
        principalId: principalId
        uniqueIdentifierForResourcesName: uniqueIdentifierForResourcesName
        tags: tags
        serviceBusQueuesNames: serviceBusQueuesNames
    }
}

/* Outputs */
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_LOCATION string = location
output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
