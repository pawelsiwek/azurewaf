// Policy #19 — Deploy budget alert per resource group
// Effect: deployIfNotExists — automatically provisions a budget + 80%/100% email alert
// on every resource group that is missing one. Proactive cost alerting without manual setup.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-19-deploy-rg-budget-alert'
  properties: {
    displayName: '[WAF Cost] Deploy budget alert on resource groups missing a budget'
    description: 'Automatically deploys a monthly cost budget with 80% and 100% email alerts to resource groups that do not already have a budget. Ensures every resource group owner is alerted before and at budget exhaustion without requiring manual budget setup per team.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      budgetAmountUSD: {
        type: 'Integer'
        metadata: {
          displayName: 'Monthly budget amount (USD)'
          description: 'Default monthly budget amount in USD to deploy on resource groups. Teams can override via their own budget after initial deployment.'
        }
        defaultValue: 500
      }
      alertEmailAddress: {
        type: 'String'
        metadata: {
          displayName: 'Alert notification email'
          description: 'Email address that receives 80% and 100% budget threshold alerts.'
        }
        defaultValue: 'azure-cost-alerts@contoso.com'
      }
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
        }
        allowedValues: [
          'deployIfNotExists'
          'auditIfNotExists'
          'disabled'
        ]
        defaultValue: 'deployIfNotExists'
      }
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Resources/subscriptions/resourceGroups'
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          type: 'Microsoft.Consumption/budgets'
          existenceScope: 'resourceGroup'
          existenceCondition: {
            field: 'Microsoft.Consumption/budgets/amount'
            greater: 0
          }
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
          ]
          deployment: {
            properties: {
              mode: 'incremental'
              template: {
                '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
                contentVersion: '1.0.0.0'
                parameters: {
                  budgetAmount: {
                    type: 'int'
                  }
                  alertEmail: {
                    type: 'string'
                  }
                  resourceGroupName: {
                    type: 'string'
                  }
                }
                resources: [
                  {
                    type: 'Microsoft.Consumption/budgets'
                    apiVersion: '2023-11-01'
                    name: '[concat(\'budget-rg-\', parameters(\'resourceGroupName\'))]'
                    properties: {
                      category: 'Cost'
                      amount: '[parameters(\'budgetAmount\')]'
                      timeGrain: 'Monthly'
                      timePeriod: {
                        startDate: '2025-01-01'
                      }
                      filter: {
                        dimensions: {
                          name: 'ResourceGroupName'
                          operator: 'In'
                          values: [
                            '[parameters(\'resourceGroupName\')]'
                          ]
                        }
                      }
                      notifications: {
                        '80PercentActual': {
                          enabled: true
                          operator: 'GreaterThan'
                          threshold: 80
                          thresholdType: 'Actual'
                          contactEmails: [
                            '[parameters(\'alertEmail\')]'
                          ]
                        }
                        '100PercentActual': {
                          enabled: true
                          operator: 'GreaterThan'
                          threshold: 100
                          thresholdType: 'Actual'
                          contactEmails: [
                            '[parameters(\'alertEmail\')]'
                          ]
                        }
                      }
                    }
                  }
                ]
              }
              parameters: {
                budgetAmount: {
                  value: '[parameters(\'budgetAmountUSD\')]'
                }
                alertEmail: {
                  value: '[parameters(\'alertEmailAddress\')]'
                }
                resourceGroupName: {
                  value: '[field(\'name\')]'
                }
              }
            }
          }
        }
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
