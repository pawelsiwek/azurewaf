// Policy #12 — Restrict Log Analytics Workspace data retention
// Effect: deny if retentionInDays exceeds the allowed maximum
// Default 730 days = 2 years of data ingestion costs. 90 days prod / 30 days dev covers 99% of needs.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-12-restrict-loganalytics-retention'
  properties: {
    displayName: '[WAF Cost] Restrict Log Analytics Workspace data retention'
    description: 'Denies Log Analytics Workspaces with data retention exceeding the allowed maximum. The default Azure setting is 730 days (charged after 31 days), silently adding months of unnecessary data retention costs. Recommended: 90 days for production, 30 days for dev/test.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      maxRetentionDays: {
        type: 'Integer'
        metadata: {
          displayName: 'Maximum allowed retention in days'
          description: 'Workspaces with retentionInDays greater than this value will be denied. First 31 days are free; every additional day is charged. Recommended: 90 for production, 30 for dev/test.'
        }
        defaultValue: 90
      }
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
        }
        allowedValues: [
          'deny'
          'audit'
          'disabled'
        ]
        defaultValue: 'deny'
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.OperationalInsights/workspaces'
          }
          {
            field: 'Microsoft.OperationalInsights/workspaces/retentionInDays'
            greater: '[parameters(\'maxRetentionDays\')]'
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
