// Policy #10 — Require Blob Lifecycle Management Policy on Storage Accounts
// Effect: auditIfNotExists — detects accounts without tiering rules (data stays in Hot forever)
// Without lifecycle rules, blobs accumulate in Hot tier indefinitely
// Hot = ~$0.018/GB/month, Cool = ~$0.01, Cold = ~$0.004, Archive = ~$0.00099
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-10-require-blob-lifecycle-policy'
  properties: {
    displayName: '[WAF Cost] Require Blob Lifecycle Management Policy on Storage Accounts'
    description: 'Audits Storage Accounts (BlobStorage or StorageV2 with blob support) that do not have a lifecycle management policy. Without tiering rules, all data remains in Hot tier indefinitely. Lifecycle policies should move infrequently accessed data to Cool (after 30 days), Cold (after 90 days) and Archive (after 180 days), reducing storage costs by up to 95%.'
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
          'auditIfNotExists'
          'disabled'
        ]
        defaultValue: 'auditIfNotExists'
      }
    }
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Storage/storageAccounts'
      }
      then: {
        effect: '[parameters(\'effect\')]'
        details: {
          type: 'Microsoft.Storage/storageAccounts/managementPolicies'
          name: 'default'
          existenceCondition: {
            field: 'Microsoft.Storage/storageAccounts/managementPolicies/policy.rules[*].name'
            exists: true
          }
        }
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
