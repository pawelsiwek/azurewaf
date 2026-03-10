// WAF Cost Optimization Guardrails — Policy Initiative (Policy Set Definition)
// Deploys all 20 cost optimization policy definitions and groups them into a single
// assignable initiative. Assign via assignments/assignment.bicep.
targetScope = 'subscription'

// --- Policy definition modules ---
module def01 'definitions/01-require-cost-tags.bicep' = {}
module def02 'definitions/02-require-expiration-tag.bicep' = {}
module def03 'definitions/03-deny-rg-without-cost-tags.bicep' = {}
module def04 'definitions/04-require-last-cost-review-tag.bicep' = {}
module def05 'definitions/05-allowed-vm-skus.bicep' = {}
module def06 'definitions/06-allowed-appservice-plan-tiers.bicep' = {}
module def07 'definitions/07-allowed-aks-node-vm-sizes.bicep' = {}
module def08 'definitions/08-max-instances-limit.bicep' = {}
module def09 'definitions/09-deny-foundry-provisioned-throughput.bicep' = {}
module def10 'definitions/10-require-blob-lifecycle-policy.bicep' = {}
module def11 'definitions/11-audit-unattached-disks.bicep' = {}
module def12 'definitions/12-restrict-loganalytics-retention.bicep' = {}
module def13 'definitions/13-audit-unused-public-ips.bicep' = {}
module def14 'definitions/14-allowed-regions.bicep' = {}
module def15 'definitions/15-allowed-sql-tiers.bicep' = {}
module def16 'definitions/16-allowed-redis-tiers.bicep' = {}
module def17 'definitions/17-require-subscription-budget.bicep' = {}
module def18 'definitions/18-require-budget-alerts.bicep' = {}
module def19 'definitions/19-deploy-rg-budget-alert.bicep' = {}
module def20 'definitions/20-audit-deallocated-vms.bicep' = {}
module def21 'definitions/21-audit-expiring-budgets.bicep' = {}

// --- Initiative (Policy Set Definition) ---
resource initiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'waf-cost-optimization-guardrails'
  properties: {
    displayName: '[WAF] Cost Optimization Guardrails Initiative'
    description: 'A comprehensive set of 21 Azure Policy definitions aligned with the Azure Well-Architected Framework Cost Optimization pillar. Covers tagging governance, compute right-sizing, storage lifecycle, networking waste prevention, database tier controls, and budget monitoring. Designed for AzureDay 2026 conference demonstration and real-world enterprise adoption.'
    policyType: 'Custom'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    // Initiative-level parameters — override defaults per assignment
    parameters: {
      // Shared: environment classification
      nonProdEnvironmentValues: {
        type: 'Array'
        defaultValue: ['Dev', 'Test', 'Sandbox', 'dev', 'test', 'sandbox']
        metadata: { displayName: 'Non-production Environment tag values' }
      }
      // Policy #01 effect
      p01Effect: {
        type: 'String'
        defaultValue: 'deny'
        allowedValues: ['deny', 'audit', 'disabled']
        metadata: { displayName: '#01 Require cost tags — effect' }
      }
      // Policy #05 VM whitelist
      allowedVmSkus: {
        type: 'Array'
        defaultValue: [
          'Standard_B1ls'
          'Standard_B1ms'
          'Standard_B1s'
          'Standard_B2ms'
          'Standard_B2s'
          'Standard_B4ms'
          'Standard_B8ms'
          'Standard_B16ms'
          'Standard_D2s_v5'
          'Standard_D4s_v5'
          'Standard_D8s_v5'
          'Standard_D16s_v5'
          'Standard_D32s_v5'
          'Standard_D2s_v4'
          'Standard_D4s_v4'
          'Standard_D8s_v4'
          'Standard_D16s_v4'
          'Standard_E2s_v5'
          'Standard_E4s_v5'
          'Standard_E8s_v5'
          'Standard_E16s_v5'
          'Standard_E32s_v5'
          'Standard_E2s_v4'
          'Standard_E4s_v4'
          'Standard_E8s_v4'
          'Standard_E16s_v4'
          'Standard_F2s_v2'
          'Standard_F4s_v2'
          'Standard_F8s_v2'
          'Standard_F16s_v2'
          'Standard_F32s_v2'
        ]
        metadata: { displayName: '#05 Allowed VM SKUs' }
      }
      // Policy #06 App Service tiers
      allowedAppServiceTiers: {
        type: 'Array'
        defaultValue: ['Free', 'Shared', 'Basic', 'Standard', 'ElasticPremium']
        metadata: { displayName: '#06 Allowed App Service Plan tiers' }
      }
      // Policy #08 max instances
      maxAllowedInstances: {
        type: 'Integer'
        defaultValue: 10
        metadata: { displayName: '#08 Maximum allowed scale-out instances/replicas' }
      }
      // Policy #12 log retention
      maxLogRetentionDays: {
        type: 'Integer'
        defaultValue: 90
        metadata: { displayName: '#12 Maximum Log Analytics retention (days)' }
      }
      // Policy #14 allowed regions
      allowedLocations: {
        type: 'Array'
        defaultValue: ['westeurope', 'northeurope', 'global']
        metadata: { displayName: '#14 Allowed Azure regions', strongType: 'location' }
      }
      // Policy #19 budget
      rgBudgetAmountUSD: {
        type: 'Integer'
        defaultValue: 500
        metadata: { displayName: '#19 Default RG monthly budget (USD)' }
      }
      alertEmailAddress: {
        type: 'String'
        defaultValue: 'azure-cost-alerts@contoso.com'
        metadata: { displayName: '#19 Budget alert email address' }
      }
    }

    policyDefinitions: [
      // --- TAGGING & GOVERNANCE ---
      {
        policyDefinitionId: def01.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-01'
        parameters: {
          effect: { value: '[parameters(\'p01Effect\')]' }
        }
      }
      {
        policyDefinitionId: def02.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-02'
        parameters: {
          nonProdEnvironmentValues: { value: '[parameters(\'nonProdEnvironmentValues\')]' }
        }
      }
      {
        policyDefinitionId: def03.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-03'
        parameters: {}
      }
      {
        policyDefinitionId: def04.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-04'
        parameters: {}
      }
      // --- COMPUTE ---
      {
        policyDefinitionId: def05.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-05'
        parameters: {
          allowedSkus: { value: '[parameters(\'allowedVmSkus\')]' }
        }
      }
      {
        policyDefinitionId: def06.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-06'
        parameters: {
          allowedTiers: { value: '[parameters(\'allowedAppServiceTiers\')]' }
        }
      }
      {
        policyDefinitionId: def07.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-07'
        parameters: {}
      }
      {
        policyDefinitionId: def08.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-08'
        parameters: {
          maxAllowedInstances: { value: '[parameters(\'maxAllowedInstances\')]' }
        }
      }
      // --- AI / FOUNDRY ---
      {
        policyDefinitionId: def09.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-09'
        parameters: {}
      }
      // --- STORAGE ---
      {
        policyDefinitionId: def10.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-10'
        parameters: {}
      }
      {
        policyDefinitionId: def11.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-11'
        parameters: {}
      }
      {
        policyDefinitionId: def12.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-12'
        parameters: {
          maxRetentionDays: { value: '[parameters(\'maxLogRetentionDays\')]' }
        }
      }
      // --- NETWORKING ---
      {
        policyDefinitionId: def13.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-13'
        parameters: {}
      }
      {
        policyDefinitionId: def14.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-14'
        parameters: {
          allowedLocations: { value: '[parameters(\'allowedLocations\')]' }
        }
      }
      // --- DATABASE & CACHE ---
      {
        policyDefinitionId: def15.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-15'
        parameters: {
          nonProdEnvironmentValues: { value: '[parameters(\'nonProdEnvironmentValues\')]' }
        }
      }
      {
        policyDefinitionId: def16.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-16'
        parameters: {
          nonProdEnvironmentValues: { value: '[parameters(\'nonProdEnvironmentValues\')]' }
        }
      }
      // --- BUDGET MONITORING ---
      {
        policyDefinitionId: def17.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-17'
        parameters: {}
      }
      {
        policyDefinitionId: def18.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-18'
        parameters: {}
      }
      {
        policyDefinitionId: def19.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-19'
        parameters: {
          budgetAmountUSD: { value: '[parameters(\'rgBudgetAmountUSD\')]' }
          alertEmailAddress: { value: '[parameters(\'alertEmailAddress\')]' }
        }
      }
      // --- COMPUTE (runtime audit) ---
      {
        policyDefinitionId: def20.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-20'
        parameters: {
          nonProdEnvironmentValues: { value: '[parameters(\'nonProdEnvironmentValues\')]' }
        }
      }
      // --- BUDGET EXPIRY ---
      {
        policyDefinitionId: def21.outputs.policyDefinitionId
        policyDefinitionReferenceId: 'waf-cost-21'
        parameters: {}
      }
    ]
  }
}

output initiativeId string = initiative.id
output initiativeName string = initiative.name
