// Policy #02 — Require ExpirationDate tag on non-prod resources
// Effect: audit — flags non-prod resources without expiry date (zombie resource prevention)
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-02-require-expiration-tag'
  properties: {
    displayName: '[WAF Cost] Require ExpirationDate tag on non-production resources'
    description: 'Audits non-production resources (Environment = Dev or Test) that are missing the ExpirationDate tag. Without an expiry date, temporary resources accumulate indefinitely ("zombie resources").'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      nonProdEnvironmentValues: {
        type: 'Array'
        metadata: {
          displayName: 'Non-production Environment tag values'
          description: 'Values of the Environment tag that are considered non-production.'
        }
        defaultValue: [
          'Dev'
          'Test'
          'Sandbox'
          'dev'
          'test'
          'sandbox'
        ]
      }
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
            field: 'tags[\'Environment\']'
            in: '[parameters(\'nonProdEnvironmentValues\')]'
          }
          {
            anyOf: [
              {
                field: 'tags[\'ExpirationDate\']'
                exists: false
              }
              {
                // Tag exists but was set to empty string
                field: 'tags[\'ExpirationDate\']'
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
