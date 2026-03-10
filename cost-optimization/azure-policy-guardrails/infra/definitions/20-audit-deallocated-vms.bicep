// Policy #20 — Audit deallocated (stopped) VMs in non-production environments
// Effect: audit — stopped VMs still incur storage costs and reserved capacity charges
// Note: Azure Policy reflects current powerState. For "stopped longer than N days", complement
//       with Azure Automation runbook that sets DeallocatedSince tag on VM deallocate event.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-20-audit-deallocated-vms'
  properties: {
    displayName: '[WAF Cost] Audit deallocated VMs in non-production environments'
    description: 'Audits non-production VMs currently in deallocated state. Stopped VMs still incur managed disk costs (~$5-15/month per disk) and may also have reserved IP charges. This policy flags them for owner review. For duration-based detection (stopped > N days), complement with an Automation runbook using the DeallocatedSince tag pattern.'
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
            field: 'type'
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            field: 'tags[\'Environment\']'
            in: '[parameters(\'nonProdEnvironmentValues\')]'
          }
          {
            field: 'Microsoft.Compute/virtualMachines/instanceView.statuses[*].code'
            like: 'PowerState/deallocated'
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
