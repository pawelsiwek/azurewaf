// Policy #01 — Require mandatory cost tags on resources
// Effect: deny — resource creation blocked if any required tag is missing
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-01-require-cost-tags'
  properties: {
    displayName: '[WAF Cost] Require mandatory cost tags on resources'
    description: 'Denies creation of resources missing any of the mandatory cost tags: Environment, CostCenter, Owner, Project. Without these tags cost attribution and chargeback are impossible.'
    policyType: 'Custom'
    mode: 'Indexed'
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
          'deny'
          'audit'
          'disabled'
        ]
        defaultValue: 'deny'
      }
    }
    policyRule: {
      if: {
        anyOf: [
          {
            field: 'tags[\'Environment\']'
            exists: false
          }
          {
            field: 'tags[\'CostCenter\']'
            exists: false
          }
          {
            field: 'tags[\'Owner\']'
            exists: false
          }
          {
            field: 'tags[\'Project\']'
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
