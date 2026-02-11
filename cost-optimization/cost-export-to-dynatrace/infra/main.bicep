targetScope = 'subscription'

@description('Location for all resources.')
param location string = 'eastus'

@description('Name of the Resource Group for the Function.')
param resourceGroupName string = 'rg-cost-export-dynatrace'

@description('Name of the Function App.')
param appName string = 'func-cost-dynatrace-${uniqueString(subscription().id)}'

@secure()
@description('Dynatrace API Token')
param dynatraceToken string

@description('Dynatrace API URL (e.g. https://<env>.live.dynatrace.com/api/v2/logs/ingest)')
param dynatraceUrl string

@description('Name of the specific container with cost exports')
param costExportContainerName string = 'exports'

@description('Name of the Storage Account containing Cost Exports')
param costExportStorageAccountName string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module functionApp 'modules/function.bicep' = {
  scope: rg
  name: 'functionAppDeploy'
  params: {
    location: location
    appName: appName
    storageAccountName: 'stfunc${uniqueString(subscription().id)}' // Storage for the Function itself (webjobs)
    dynatraceToken: dynatraceToken
    dynatraceUrl: dynatraceUrl
    costExportContainerName: costExportContainerName
    costExportStorageAccountName: costExportStorageAccountName
  }
}

output functionAppName string = functionApp.outputs.appName
output resourceGroupName string = resourceGroupName
output functionPrincipalId string = functionApp.outputs.principalId
