// Policy #06 — Allowed App Service Plan tiers whitelist
// Effect: deny if tier NOT in approved list
// Blocks: Premium v2, Premium v3, Isolated, IsolatedV2 (4-10x more expensive than Standard)
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-06-allowed-appservice-plan-tiers'
  properties: {
    displayName: '[WAF Cost] Allowed App Service Plan tiers whitelist'
    description: 'Denies App Service Plans with tiers not in the approved list. Blocks Premium v2/v3 (~4x Standard cost) and Isolated/IsolatedV2 tiers (~10x Standard cost) without explicit policy exemption. Use exemptions for workloads genuinely requiring VNet isolation or high performance.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      allowedTiers: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed App Service Plan tiers'
          description: 'Allowed values for the sku.tier property of App Service Plans.'
        }
        defaultValue: [
          'Free'
          'Shared'
          'Basic'
          'Standard'
          'ElasticPremium'
          // ElasticPremium is for Functions Premium Plan — reasonable for production serverless
        ]
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
            equals: 'Microsoft.Web/serverfarms'
          }
          {
            field: 'Microsoft.Web/serverfarms/sku.tier'
            notIn: '[parameters(\'allowedTiers\')]'
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
