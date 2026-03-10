// Policy #03 — Tag resource groups without cost tags
// Effect: modify (default) — auto-adds placeholder tags remediable via Remediation Task in portal
//         deny            — hard block, use after initial cleanup
// Remediation: Policy → Compliance → waf-cost-03 → Create Remediation Task → Approve
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-03-deny-rg-without-cost-tags'
  properties: {
    displayName: '[WAF Cost] Deny resource groups without cost tags'
    description: 'Flags resource groups missing Environment or CostCenter tags. Default effect \'modify\' automatically adds placeholder tag values (\'UNSET\') via a Remediation Task — navigate to Policy → Compliance → waf-cost-03 → Create Remediation Task to trigger auto-fix. Switch effect to \'deny\' after initial cleanup to harden the guardrail.'
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
          description: 'modify = auto-add placeholder tags (remediable); deny = hard block; audit = report only'
        }
        allowedValues: [
          'modify'
          'deny'
          'audit'
          'disabled'
        ]
        defaultValue: 'modify'
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
                field: 'tags[\'Environment\']'
                exists: false
              }
              {
                field: 'tags[\'Environment\']'
                equals: ''
              }
              {
                field: 'tags[\'CostCenter\']'
                exists: false
              }
              {
                field: 'tags[\'CostCenter\']'
                equals: ''
              }
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          // Contributor role required for Modify remediation tasks
          roleDefinitionIds: [
            '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
          ]
          operations: [
            {
              // 'add' only sets the tag if it doesn't already exist (preserves existing values)
              operation: 'add'
              field: 'tags[\'Environment\']'
              value: 'UNSET'
            }
            {
              operation: 'add'
              field: 'tags[\'CostCenter\']'
              value: 'UNSET'
            }
          ]
        }
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
