// Policy #13 — Audit unused public IP addresses
// Effect: audit — static public IPs without association still incur charges
// Standard static public IP = ~$3.60/month. Hundreds across enterprise = thousands wasted.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-13-audit-unused-public-ips'
  properties: {
    displayName: '[WAF Cost] Audit unused (unassociated) public IP addresses'
    description: 'Audits Standard and Basic static public IP addresses that are not associated with any resource (no ipConfiguration, natGateway, or publicIPPrefix). At ~$3.60/month each, hundreds of orphaned IPs cost thousands per month across large estates.'
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
          'audit'
          'deny'
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
            equals: 'Microsoft.Network/publicIPAddresses'
          }
          {
            field: 'Microsoft.Network/publicIPAddresses/ipConfiguration.id'
            exists: false
          }
          {
            field: 'Microsoft.Network/publicIPAddresses/natGateway.id'
            exists: false
          }
          {
            // Only flag static allocation — dynamic IPs are free when not in use
            field: 'Microsoft.Network/publicIPAddresses/publicIPAllocationMethod'
            equals: 'Static'
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
