#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys the WAF Cost Optimization Guardrails Azure Policy initiative.

.DESCRIPTION
    Performs a two-step deployment:
    1. Deploys all 25 policy definitions + the initiative (policySetDefinition)
    2. Assigns the initiative to the current subscription (or Management Group if specified)

.PARAMETER SubscriptionId
    Target Azure Subscription ID. Defaults to the current az CLI subscription.

.PARAMETER Location
    Azure region for the deployment metadata and managed identity. Default: westeurope.

.PARAMETER AlertEmail
    Email address for budget alert notifications. Required for policy #23.

.PARAMETER RgBudgetUSD
    Default monthly budget (USD) auto-deployed to resource groups missing one. Default: 500.

.PARAMETER MaxInstances
    Maximum allowed scale-out instances/replicas (policy #10). Default: 10.

.PARAMETER MaxLogRetentionDays
    Maximum Log Analytics data retention in days (policy #15). Default: 90.

.PARAMETER AllowedLocations
    Comma-separated list of allowed Azure regions. Default: 'westeurope,northeurope'.

.PARAMETER AuditMode
    If set, all Deny effects are relaxed to Audit for initial rollout assessment.

.PARAMETER WhatIf
    Runs az deployment in --what-if mode without making changes.

.EXAMPLE
    ./deploy.ps1 -AlertEmail "cost@mycompany.com" -AuditMode

.EXAMPLE
    ./deploy.ps1 -AlertEmail "cost@mycompany.com" -RgBudgetUSD 1000 -MaxInstances 20
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $SubscriptionId = '',  # TODO: set your subscription ID
    [string] $Location = 'westeurope',
    [Parameter(Mandatory)]
    [string] $AlertEmail,
    [int]    $RgBudgetUSD = 500,
    [int]    $MaxInstances = 10,
    [int]    $MaxLogRetentionDays = 90,
    [string] $AllowedLocations = 'westeurope,northeurope',
    [switch] $AuditMode,
    [switch] $WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot

# --- 1. Validate Azure CLI login ---
Write-Host "`n[1/4] Checking Azure CLI login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Error "Not logged in to Azure CLI. Run 'az login' first."
    exit 1
}

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId
    $account = az account show | ConvertFrom-Json
}

Write-Host "  Subscription : $($account.name) ($($account.id))" -ForegroundColor Green
Write-Host "  Tenant       : $($account.tenantId)" -ForegroundColor Green

# --- 2. Deploy initiative (definitions + policySetDefinition) ---
Write-Host "`n[2/4] Deploying policy definitions and initiative..." -ForegroundColor Cyan

$initiativeArgs = @(
    'deployment', 'sub', 'create'
    '--location', $Location
    '--template-file', "$ScriptDir/infra/initiative.bicep"
    '--name', "waf-cost-initiative-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
)
if ($WhatIf) { $initiativeArgs += '--what-if' }

$initiativeResult = az @initiativeArgs | ConvertFrom-Json

if (-not $WhatIf) {
    $initiativeId = $initiativeResult.properties.outputs.initiativeId.value
    Write-Host "  Initiative ID: $initiativeId" -ForegroundColor Green
} else {
    Write-Host "  (what-if mode — no changes made)" -ForegroundColor Yellow
    exit 0
}

# --- 3. Build assignment parameters ---
Write-Host "`n[3/4] Preparing assignment parameters..." -ForegroundColor Cyan

$locationsArray = ($AllowedLocations -split ',').Trim() | ForEach-Object { $_ } | ConvertTo-Json -Compress
$p01Effect = if ($AuditMode) { 'audit' } else { 'deny' }

if ($AuditMode) {
    Write-Host "  Audit mode enabled — deny effects relaxed to audit for initial assessment." -ForegroundColor Yellow
}

# --- 4. Deploy assignment ---
Write-Host "`n[4/4] Assigning initiative to subscription..." -ForegroundColor Cyan

$assignArgs = @(
    'deployment', 'sub', 'create'
    '--location', $Location
    '--template-file', "$ScriptDir/infra/assignments/assignment.bicep"
    '--name', "waf-cost-assignment-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    '--parameters',
        "initiativeId=$initiativeId",
        "alertEmailAddress=$AlertEmail",
        "rgBudgetAmountUSD=$RgBudgetUSD",
        "maxAllowedInstances=$MaxInstances",
        "maxLogRetentionDays=$MaxLogRetentionDays",
        "p01Effect=$p01Effect",
        "managedIdentityLocation=$Location"
    '--parameters', "allowedLocations=$locationsArray"
)

$assignResult = az @assignArgs | ConvertFrom-Json
$assignmentId = $assignResult.properties.outputs.assignmentId.value

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  WAF Cost Optimization Guardrails deployed!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Assignment ID : $assignmentId" -ForegroundColor Green
Write-Host "  Mode          : $(if ($AuditMode) { 'Audit (assessment)' } else { 'Enforce (deny)' })" -ForegroundColor Green
Write-Host "`n  Next steps:" -ForegroundColor Cyan
Write-Host "  1. Check compliance: https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Compliance" -ForegroundColor Gray
Write-Host "  2. Review non-compliant resources before switching to Deny mode" -ForegroundColor Gray
Write-Host "  3. Create exemptions for legitimate exceptions: az policy exemption create ..." -ForegroundColor Gray
