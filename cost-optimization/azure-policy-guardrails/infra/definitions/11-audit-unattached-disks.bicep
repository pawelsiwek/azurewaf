// Policy #11 — Audit unattached managed disks
// Effect: audit — unattached disks pay full storage price with zero value
// A forgotten P30 premium disk = ~$130/month per disk
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-11-audit-unattached-disks'
  properties: {
    displayName: '[WAF Cost] Audit unattached managed disks'
    description: 'Audits managed disks that are not attached to any virtual machine (diskState = Unattached). These disks incur full storage costs with no compute benefit — a single forgotten P30 premium disk costs ~$130/month. Disks in Reserved state (used by Azure) are excluded.'
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
            equals: 'Microsoft.Compute/disks'
          }
          {
            field: 'Microsoft.Compute/disks/diskState'
            equals: 'Unattached'
          }
          // Exclude OS disks of deallocated VMs — they have diskState=Reserved when VM is running
          // diskState=Unattached means truly orphaned disk
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
