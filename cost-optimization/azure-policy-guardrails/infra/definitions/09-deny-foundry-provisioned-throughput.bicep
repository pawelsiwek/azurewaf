// Policy #09 — Deny Microsoft AI Foundry / Azure OpenAI Provisioned Throughput Units (PTU)
// Effect: deny — PTU deployments start at ~$1,500/month per 100 units minimum commitment
// Blocks: ProvisionedManaged and Provisioned SKU on Cognitive Services / AI Foundry deployments
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-09-deny-foundry-provisioned-throughput'
  properties: {
    displayName: '[WAF Cost] Deny AI Foundry / Azure OpenAI Provisioned Throughput (PTU)'
    description: 'Denies creation of Azure OpenAI or AI Foundry model deployments with Provisioned Throughput Unit (PTU) SKUs. PTU plans commit to a fixed monthly cost starting at ~$1,500/month regardless of actual usage. Use Pay-As-You-Go token-based SKUs during development and require explicit policy exemption for production PTU commitments.'
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
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.CognitiveServices/accounts/deployments'
          }
          {
            anyOf: [
              {
                field: 'Microsoft.CognitiveServices/accounts/deployments/sku.name'
                equals: 'ProvisionedManaged'
              }
              {
                field: 'Microsoft.CognitiveServices/accounts/deployments/sku.name'
                equals: 'Provisioned'
              }
              {
                field: 'Microsoft.CognitiveServices/accounts/deployments/sku.name'
                equals: 'GlobalProvisionedManaged'
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
