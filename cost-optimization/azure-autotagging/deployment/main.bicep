@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Function App')
param functionAppName string = 'func-autotagging-${uniqueString(resourceGroup().id)}'

@description('Storage Account name for Function App')
param storageAccountName string = 'stautotagging${uniqueString(resourceGroup().id)}'

@description('App Service Plan name')
param appServicePlanName string = 'asp-autotagging-${uniqueString(resourceGroup().id)}'

@description('Application Insights name')
param appInsightsName string = 'appi-autotagging-${uniqueString(resourceGroup().id)}'

@description('Azure Subscription ID for tagging')
param azureSubscriptionId string

@description('Environment name')
param environment string = 'Production'

@description('Cost Center for tagging')
param costCenter string = 'IT-Operations'

@description('Function App runtime')
param functionWorkerRuntime string = 'python'

@description('Python version')
param pythonVersion string = '3.11'

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
  tags: {
    Environment: environment
    CostCenter: costCenter
    Purpose: 'AutoTagging Function Storage'
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
  tags: {
    Environment: environment
    CostCenter: costCenter
    Purpose: 'AutoTagging Function Monitoring'
  }
}

// App Service Plan (Consumption Plan)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true // Required for Linux
  }
  tags: {
    Environment: environment
    CostCenter: costCenter
    Purpose: 'AutoTagging Function Hosting'
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'Python|${pythonVersion}'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'AZURE_SUBSCRIPTION_ID'
          value: azureSubscriptionId
        }
        {
          name: 'ENVIRONMENT'
          value: environment
        }
        {
          name: 'COST_CENTER'
          value: costCenter
        }
      ]
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  tags: {
    Environment: environment
    CostCenter: costCenter
    Purpose: 'AutoTagging Function App'
  }
}

output functionAppName string = functionApp.name
output functionAppPrincipalId string = functionApp.identity.principalId
output functionAppUrl string = 'https://${functionApp.properties.defaultHostName}'
