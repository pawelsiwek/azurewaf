using 'assignment.bicep'

// WAF Cost Optimization Guardrails — Assignment Parameters
// Adjust values for your organization before deploying.
//
// Deploy order:
//   1. az deployment sub create -l westeurope -f ../initiative.bicep
//      (capture output.initiativeId)
//   2. az deployment sub create -l westeurope -f assignment.bicep -p assignment.bicepparam

// Get this value from the initiative.bicep deployment output
// Run: az deployment sub create -l westeurope -f ../initiative.bicep --query 'properties.outputs.initiativeId.value'
param initiativeId = '/subscriptions/<YOUR-SUBSCRIPTION-ID>/providers/Microsoft.Authorization/policySetDefinitions/waf-cost-optimization-guardrails'

param assignmentDisplayName = 'WAF Cost Optimization Guardrails'

// Environments considered non-production — adjust to match your tagging convention
param nonProdEnvironmentValues = [
  'Dev'
  'Test'
  'Sandbox'
  'dev'
  'test'
  'sandbox'
]

// Start with 'audit' for initial rollout, then switch to 'deny' after reviewing compliance
param p01Effect = 'audit'

// Extend this list with any additional approved VM SKUs for your workloads
param allowedVmSkus = [
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

// Allowed App Service Plan tiers allowed without exemption
param allowedAppServiceTiers = [
  'Free'
  'Shared'
  'Basic'
  'Standard'
  'ElasticPremium'
]

// Maximum scale-out limit — requires policy exemption to exceed
param maxAllowedInstances = 10

// Log Analytics max retention — first 31 days free, every additional day charged
param maxLogRetentionDays = 90

// Only deploy to West Europe and North Europe — add regions for multi-region architectures
param allowedLocations = [
  'westeurope'
  'northeurope'
  'global'
]

// Default budget per resource group — teams can set their own after initial deployment
param rgBudgetAmountUSD = 500

// Central cost alert mailbox — replace with your organization's alias
param alertEmailAddress = 'azure-cost-alerts@contoso.com'

param managedIdentityLocation = 'westeurope'
