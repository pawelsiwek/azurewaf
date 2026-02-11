# Usage: .\deploy.ps1 -SubscriptionId "..." -DynatraceUrl "..." -DynatraceToken "..." -CostExportStorageAccountName "..."

param(
    [string]$SubscriptionId,
    [string]$Location = "eastus",
    [string]$ResourceGroupName = "rg-cost-export-dynatrace",
    [string]$DynatraceUrl,
    [string]$DynatraceToken,
    [string]$CostExportStorageAccountName,
    [string]$CostExportContainerName = "exports"
)

if (-not $SubscriptionId) { Write-Error "SubscriptionId is required."; exit 1 }
if (-not $DynatraceUrl) { Write-Error "DynatraceUrl is required."; exit 1 }
if (-not $DynatraceToken) { Write-Error "DynatraceToken is required."; exit 1 }
if (-not $CostExportStorageAccountName) { Write-Error "CostExportStorageAccountName is required."; exit 1 }

# Set subscription
az account set --subscription $SubscriptionId

# Build
Write-Host "Building .NET Function..."
dotnet build src/CostExportToDynatrace/CostExportToDynatrace.csproj -c Release
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Publishing .NET Function..."
dotnet publish src/CostExportToDynatrace/CostExportToDynatrace.csproj -c Release -o ./publish
if ($LASTEXITCODE -ne 0) { exit 1 }

# Deploy Infrastructure
Write-Host "Deploying Infrastructure (Bicep)..."
$deploymentName = "cost-dynatrace-deploy-$(Get-Date -Format 'yyyyMMddHHmm')"

$bicepOutput = az deployment sub create --location $Location `
    --template-file infra/main.bicep `
    --name $deploymentName `
    --output json `
    --parameters location=$Location `
                 resourceGroupName=$ResourceGroupName `
                 dynatraceUrl=$DynatraceUrl `
                 dynatraceToken=$DynatraceToken `
                 costExportStorageAccountName=$CostExportStorageAccountName `
                 costExportContainerName=$CostExportContainerName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Infrastructure deployment failed."
    Write-Host $bicepOutput
    exit 1
}

$outputs = $bicepOutput | ConvertFrom-Json
$functionAppName = $outputs.properties.outputs.functionAppName.value
$resourceGroupName = $outputs.properties.outputs.resourceGroupName.value
$functionPrincipalId = $outputs.properties.outputs.functionPrincipalId.value

Write-Host "Infrastructure deployed."
Write-Host "Function App: $functionAppName"
Write-Host "Principal ID: $functionPrincipalId"

# Grant permission to Cost Export Storage? 
# We cannot do this easily if the storage is in another subscription or if the user executing doesn't have permissions on it.
# We will just verify or print instructions.

Write-Host "IMPORTANT: Ensure that the Function App Managed Identity ($functionPrincipalId) has 'Storage Blob Data Reader' role on storage account '$CostExportStorageAccountName'."

# Zip Deploy
Write-Host "Zipping and Deploying Code..."
Compress-Archive -Path ./publish/* -DestinationPath ./publish/func.zip -Force

az functionapp deployment source config-zip --resource-group $resourceGroupName --name $functionAppName --src ./publish/func.zip

Write-Host "Deployment Complete!"
