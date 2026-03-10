// Policy #07 — Allowed AKS node pool VM sizes whitelist
// Effect: deny if node VM size NOT in approved list
// Blocks: GPU series (NC/ND/NV/NG = 3-30x CPU price), M-series, HB/HC HPC nodes
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-07-allowed-aks-node-vm-sizes'
  properties: {
    displayName: '[WAF Cost] Allowed AKS node pool VM sizes whitelist'
    description: 'Denies AKS agent pools using VM sizes not in the approved list. Blocks GPU (NC/ND/NV/NG series, 3-30x CPU price) and HPC (HB/HC) nodes that are frequently accidentally selected. Use policy exemptions for legitimate ML/GPU workloads.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      allowedVmSizes: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed node VM sizes'
          description: 'Whitelist of permitted VM sizes for AKS agent pools.'
        }
        defaultValue: [
          // B-series (burstable)
          'Standard_B2ms'
          'Standard_B4ms'
          'Standard_B8ms'
          // D-series v4/v5
          'Standard_D2s_v5'
          'Standard_D4s_v5'
          'Standard_D8s_v5'
          'Standard_D16s_v5'
          'Standard_D32s_v5'
          'Standard_D2s_v4'
          'Standard_D4s_v4'
          'Standard_D8s_v4'
          'Standard_D16s_v4'
          // E-series v4/v5
          'Standard_E2s_v5'
          'Standard_E4s_v5'
          'Standard_E8s_v5'
          'Standard_E16s_v5'
          'Standard_E8s_v4'
          'Standard_E16s_v4'
          // F-series
          'Standard_F4s_v2'
          'Standard_F8s_v2'
          'Standard_F16s_v2'
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
            equals: 'Microsoft.ContainerService/managedClusters/agentPools'
          }
          {
            field: 'Microsoft.ContainerService/managedClusters/agentPools/vmSize'
            notIn: '[parameters(\'allowedVmSizes\')]'
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
