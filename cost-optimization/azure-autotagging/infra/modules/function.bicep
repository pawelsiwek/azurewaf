targetScope = 'resourceGroup'

param location string
param appName string
param storageAccountName string
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${appName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-functions'
        properties: {
          addressPrefix: '10.100.1.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: 'Y1' 
    tier: 'Dynamic'
  }
  properties: {}
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-ai'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(appName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
  tags: tags
}


// Network Security Perimeter (NSP) - Preview feature
resource nsp 'Microsoft.Network/networkSecurityPerimeters@2023-07-01-preview' = {
  name: '${appName}-nsp'
  location: location
  properties: {
    description: 'Perimeter for Cost Export Function and Storage'
    displayName: 'CostExportPerimeter'
  }
}

resource nspProfile 'Microsoft.Network/networkSecurityPerimeters/profiles@2023-07-01-preview' = {
  parent: nsp
  name: 'default'
  location: location
}

// Associate Function App
resource functionAssociation 'Microsoft.Network/networkSecurityPerimeters/resourceAssociations@2023-07-01-preview' = {
  parent: nsp
  name: '${appName}-assoc'
  location: location
  properties: {
    privateLinkResource: {
      id: functionApp.id
    }
    profile: {
      id: nspProfile.id
    }
    accessMode: 'Learning' 
  }
}

output principalId string = functionApp.identity.principalId
output functionId string = functionApp.id
output appName string = functionApp.name
output subnetId string = virtualNetwork.properties.subnets[0].id

