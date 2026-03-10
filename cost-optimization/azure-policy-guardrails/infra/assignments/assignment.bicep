// Assignment of the WAF Cost Optimization Guardrails initiative
// Deploy this after initiative.bicep has been applied to register the initiative.
// Scope: subscription (default) — change to Management Group for enterprise-wide rollout.
//
// Usage:
//   az deployment sub create \
//     --location westeurope \
//     --template-file assignment.bicep \
//     --parameters assignment.bicepparam
targetScope = 'subscription'

@description('Resource ID of the WAF Cost Optimization Guardrails initiative. Get from initiative.bicep output.')
param initiativeId string

@description('Display name for the policy assignment shown in Azure Portal.')
param assignmentDisplayName string = 'WAF Cost Optimization Guardrails'

@description('Non-production Environment tag values used across multiple policies.')
param nonProdEnvironmentValues array = [
  'Dev'
  'Test'
  'Sandbox'
  'dev'
  'test'
  'sandbox'
]

@description('Effect for policy #01 — require mandatory cost tags.')
@allowed(['deny', 'audit', 'disabled'])
param p01Effect string = 'deny'

@description('Allowed VM SKU names whitelist (policy #05).')
param allowedVmSkus array = [
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

@description('Allowed App Service Plan tier names (policy #06).')
param allowedAppServiceTiers array = ['Free', 'Shared', 'Basic', 'Standard', 'ElasticPremium']

@description('Maximum allowed scale-out instances/replicas (policy #08).')
param maxAllowedInstances int = 10

@description('Maximum Log Analytics data retention in days (policy #12).')
param maxLogRetentionDays int = 90

@description('Allowed Azure region names whitelist (policy #14).')
param allowedLocations array = ['westeurope', 'northeurope', 'global']

@description('Default monthly budget amount in USD per resource group (policy #19).')
param rgBudgetAmountUSD int = 500

@description('Email address for budget alert notifications (policy #19).')
param alertEmailAddress string = 'azure-cost-alerts@contoso.com'

@description('Managed identity location for DeployIfNotExists policies.')
param managedIdentityLocation string = 'westeurope'

// Assignment
resource assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'waf-cost-guardrails'
  location: managedIdentityLocation
  identity: {
    // System-assigned managed identity required for deployIfNotExists policies (#06, #23)
    type: 'SystemAssigned'
  }
  properties: {
    displayName: assignmentDisplayName
    description: 'Enforces WAF Cost Optimization guardrails: tagging, compute sizing, storage lifecycle, networking waste, database tiers and budget monitoring.'
    policyDefinitionId: initiativeId
    enforcementMode: 'Default'
    parameters: {
      nonProdEnvironmentValues: { value: nonProdEnvironmentValues }
      p01Effect: { value: p01Effect }
      allowedVmSkus: { value: allowedVmSkus }
      allowedAppServiceTiers: { value: allowedAppServiceTiers }
      maxAllowedInstances: { value: maxAllowedInstances }
      maxLogRetentionDays: { value: maxLogRetentionDays }
      allowedLocations: { value: allowedLocations }
      rgBudgetAmountUSD: { value: rgBudgetAmountUSD }
      alertEmailAddress: { value: alertEmailAddress }
    }
  }
}

// Role assignments for the managed identity (required for deployIfNotExists policies)
// Contributor at subscription scope — restrict to minimum required roles for production use.
resource roleAssignmentContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(assignment.id, 'contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b24988ac-6180-42a0-ab88-20f7382dd24c' // Contributor
    )
    principalId: assignment.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output assignmentId string = assignment.id
output assignmentPrincipalId string = assignment.identity.principalId
