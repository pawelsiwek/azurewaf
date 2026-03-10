// Policy #04 — Require LastCostReview tag on Resource Groups and Subscriptions
// Effect: audit — scoped to RGs only (subscription-level review tracked via RG)
// Note: Azure Policy cannot natively compare date values to "today minus N days".
//       For staleness detection complement with an Automation runbook.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-04-require-last-cost-review-tag'
  properties: {
    displayName: '[WAF Cost] Require LastCostReview tag on Resource Groups'
    description: 'Audits resource groups missing the LastCostReview tag (ISO format YYYY-MM-DD). Scoped to RGs — one review covers all resources inside, avoiding per-resource noise. Tag should be updated quarterly. Complement with an Automation runbook to flag RGs where the date exceeds the review interval (e.g. >90 days).'
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
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            anyOf: [
              {
                field: 'tags[\'LastCostReview\']'
                exists: false
              }
              {
                field: 'tags[\'LastCostReview\']'
                equals: ''
              }
            ]
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
