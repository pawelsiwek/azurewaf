// Policy #17 — Require budget on subscription
// Effect: auditIfNotExists — subscription without ANY budget is flying blind on costs
// First step in cost governance: if there's no budget, there's no alert
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-17-require-subscription-budget'
  properties: {
    displayName: '[WAF Cost] Require at least one budget on subscription'
    description: 'Audits subscriptions that do not have any Azure Cost Management budget defined. Without a budget there are no spending alerts — cost overruns are only discovered in the monthly invoice. This is the baseline cost governance control for every subscription.'
    policyType: 'Custom'
    mode: 'All'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
        }
        allowedValues: [
          'auditIfNotExists'
          'disabled'
        ]
        defaultValue: 'auditIfNotExists'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions'
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          type: 'Microsoft.Consumption/budgets'
          existenceScope: 'subscription'
          existenceCondition: {
            field: 'Microsoft.Consumption/budgets/amount'
            greater: 0
          }
        }
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
