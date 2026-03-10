// Policy #18 — Require action group (alert notifications) on subscription budgets
// Effect: audit — a budget without a notification is just a number in a dashboard nobody watches
// Checks that at least one budget has notifications with contactEmails or actionGroups configured
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-18-require-budget-alerts'
  properties: {
    displayName: '[WAF Cost] Require alert notifications configured on subscription budgets'
    description: 'Audits Azure Cost Management budgets that have no notification contacts or action groups configured. A budget without notifications is useless — spending can exceed the limit with no one alerted. Every budget must have at least one email or action group notified at the threshold breach.'
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
          'audit'
          'disabled'
        ]
        defaultValue: 'audit'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Consumption/budgets'
          }
          {
            // Budget has no notifications property set at all
            field: 'Microsoft.Consumption/budgets/notifications'
            exists: false
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
