/* Parameters */
param environmentName string
param location string = resourceGroup().location
param uniqueIdentifierForResourcesName string = ''
param tags object

/* Variables */
var abbreviations = loadJsonContent('../abbreviations.json')

/* Resources */
// Log analytics workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${abbreviations.operationalInsightsWorkspaces}${environmentName}-${uniqueIdentifierForResourcesName}'
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

// Application insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${abbreviations.insightsComponents}${environmentName}-${uniqueIdentifierForResourcesName}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
  }
}

/* Outputs */
output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output applicationInsightsId string = applicationInsights.id
output applicationInsightsName string = applicationInsights.name
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
