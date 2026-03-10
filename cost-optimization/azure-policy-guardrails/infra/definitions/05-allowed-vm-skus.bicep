// Policy #05 — Allowed VM SKUs whitelist
// Effect: deny if VM SKU is NOT in the approved list
// Excludes: M-series, L-series, X-series, NV/NC/ND/NG (GPU), HB/HC/H (HPC) — all extremely expensive
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-05-allowed-vm-skus'
  properties: {
    displayName: '[WAF Cost] Allowed VM SKUs whitelist'
    description: 'Denies creation of VMs with SKUs not in the approved list. Blocks expensive M-series ($28k+/month), GPU (NC/ND/NV/NG), and HPC (HB/HC) series without explicit policy exemption.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      allowedSkus: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed VM SKU names'
          description: 'Whitelist of permitted VM sizes. Extend via policy exemption for special workloads.'
        }
        defaultValue: [
          // B-series (burstable — dev/test)
          'Standard_B1ls'
          'Standard_B1ms'
          'Standard_B1s'
          'Standard_B2ms'
          'Standard_B2s'
          'Standard_B4ms'
          'Standard_B8ms'
          'Standard_B16ms'
          // D-series v4/v5 (general purpose)
          'Standard_D2s_v5'
          'Standard_D4s_v5'
          'Standard_D8s_v5'
          'Standard_D16s_v5'
          'Standard_D32s_v5'
          'Standard_D2s_v4'
          'Standard_D4s_v4'
          'Standard_D8s_v4'
          'Standard_D16s_v4'
          'Standard_D32s_v4'
          // E-series v4/v5 (memory optimized — up to 32 cores)
          'Standard_E2s_v5'
          'Standard_E4s_v5'
          'Standard_E8s_v5'
          'Standard_E16s_v5'
          'Standard_E32s_v5'
          'Standard_E2s_v4'
          'Standard_E4s_v4'
          'Standard_E8s_v4'
          'Standard_E16s_v4'
          'Standard_E32s_v4'
          // F-series (compute optimized)
          'Standard_F2s_v2'
          'Standard_F4s_v2'
          'Standard_F8s_v2'
          'Standard_F16s_v2'
          'Standard_F32s_v2'
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
            equals: 'Microsoft.Compute/virtualMachines'
          }
          {
            field: 'Microsoft.Compute/virtualMachines/sku.name'
            notIn: '[parameters(\'allowedSkus\')]'
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
