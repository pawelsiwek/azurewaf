// Policy #21 — Audit time-limited budgets (endDate set — will stop tracking on expiry)
// Effect: audit — flags Cost Management budgets that have an explicit end date configured.
//
// WHY THIS MATTERS:
//   A budget with endDate = 2024-12-31 silently stops tracking after that date.
//   Nobody notices. Spend keeps going. No alert fires. Classic zombie budget.
//   This policy surfaces ALL time-limited budgets for manual review.
//
// NOTE: Azure Policy cannot compare dates to "today" — staleness detection
//       (endDate < today) requires an Automation runbook or Logic App.
//       This policy is the lightweight governance gate: know which budgets will expire.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-21-audit-expiring-budgets'
  properties: {
    displayName: '[WAF Cost] Audit time-limited Cost Management budgets (review expiration date)'
    description: 'Audits Azure Cost Management budgets that have an explicit endDate configured. A budget with an end date silently stops monitoring and alerting after that date — spend continues unchecked with no notifications. All flagged budgets should be reviewed: either extend the end date, convert to a recurring budget (remove endDate), or explicitly decommission. Complement with an Automation runbook to flag budgets where endDate < today.'
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
            // Budget has an explicit end date — will stop tracking after that date
            field: 'Microsoft.Consumption/budgets/timePeriod.endDate'
            exists: true
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
