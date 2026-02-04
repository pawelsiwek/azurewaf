targetScope = 'subscription'

param functionAppId string
param functionName string = 'AutoTagResource'
param principalId string

resource eventSubscription 'Microsoft.EventGrid/eventSubscriptions@2022-06-15' = {
  name: 'evs-autotagging'
  properties: {
    destination: {
      endpointType: 'AzureFunction'
      properties: {
        resourceId: '${functionAppId}/functions/${functionName}'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Resources.ResourceWriteSuccess'
      ]
      enableAdvancedFilteringOnArrays: true
      advancedFilters: [
        {
          operatorType: 'StringNotContains'
          key: 'data.claims.oid'
          values: [
            principalId
          ]
        }
      ]
    }
    eventDeliverySchema: 'EventGridSchema'
  }
}
