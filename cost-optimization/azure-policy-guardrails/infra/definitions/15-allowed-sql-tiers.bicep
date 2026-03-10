// Policy #15 — Allowed SQL Database tiers whitelist (non-production)
// Effect: deny if sku.tier NOT in allowed list for non-prod environments
// Business Critical = 5x cost of General Purpose for the same performance in dev/test
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-15-allowed-sql-tiers'
  properties: {
    displayName: '[WAF Cost] Allowed SQL Database service tiers whitelist (non-production)'
    description: 'Denies non-production Azure SQL Databases with tiers not in the approved list. Business Critical tier costs 5x more than General Purpose for equivalent dev/test performance (built-in in-memory OLTP and read replicas that tests never use). Hyperscale is allowed only for specific performance testing via policy exemption.'
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
          displayName: 'Allowed SQL Database tiers (non-prod)'
          description: 'Allowed values for sku.tier on Microsoft.Sql/servers/databases in non-production environments.'
        }
        defaultValue: [
          'GeneralPurpose'
          'Standard'
          'Basic'
          'Free'
          'Serverless'
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
            equals: 'Microsoft.Sql/servers/databases'
          }
          {
            field: 'tags[\'Environment\']'
            in: '[parameters(\'nonProdEnvironmentValues\')]'
          }
          {
            field: 'Microsoft.Sql/servers/databases/sku.tier'
            notIn: '[parameters(\'allowedTiers\')]'
          }
          {
            // Exclude the master database which Azure creates automatically
            field: 'name'
            notEquals: 'master'
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
