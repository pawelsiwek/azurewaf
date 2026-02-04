targetScope = 'subscription'

@description('Location for all resources.')
param location string = 'eastus'

@description('Name of the Resource Group.')
param resourceGroupName string = 'rg-autotagging'

@description('Name of the Function App.')
param appName string = 'func-autotagging-${uniqueString(subscription().id)}'

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
    storageAccountName: 'stauto${uniqueString(subscription().id)}'
  }
}

// Role Assignments
var tagContributorRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4a9ae827-6dc8-4573-8ac7-8239d42aa03f')
var readerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')

resource tagContributorAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroupName, appName, 'TagContributor')
  properties: {
    roleDefinitionId: tagContributorRole
    principalId: functionApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

resource readerAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, resourceGroupName, appName, 'Reader')
  properties: {
    roleDefinitionId: readerRole
    principalId: functionApp.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppName string = functionApp.outputs.appName
output resourceGroupName string = resourceGroupName
output functionAppId string = functionApp.outputs.functionId
output functionPrincipalId string = functionApp.outputs.principalId
