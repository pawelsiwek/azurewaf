// Policy #16 — Allowed Azure Cache for Redis tiers whitelist (non-production)
// Effect: deny if sku.name = Premium for non-prod environments
// Premium P1 = ~$500/month vs Standard C1 = ~$55/month — 10x price difference for dev/test
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-16-allowed-redis-tiers'
  properties: {
    displayName: '[WAF Cost] Allowed Azure Cache for Redis tiers whitelist (non-production)'
    description: 'Denies Premium Azure Cache for Redis instances in non-production environments. Premium P1 costs ~$500/month vs Standard C1 at ~$55/month — a 10x difference with no measurable benefit for dev/test workloads (VNet injection, persistence and geo-replication are irrelevant outside production).'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      allowedSkuNames: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed Redis SKU names (non-prod)'
        }
        defaultValue: [
          'Basic'
          'Standard'
        ]
      }
      nonProdEnvironmentValues: {
        type: 'Array'
        metadata: {
          displayName: 'Non-production Environment tag values'
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
            equals: 'Microsoft.Cache/redis'
          }
          {
            field: 'tags[\'Environment\']'
            in: '[parameters(\'nonProdEnvironmentValues\')]'
          }
          {
            field: 'Microsoft.Cache/redis/sku.name'
            notIn: '[parameters(\'allowedSkuNames\')]'
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
