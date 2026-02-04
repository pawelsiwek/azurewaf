# Usage: .\deploy.ps1 -SubscriptionId "your-subscription-id" -TenantId "your-tenant-id" -Location "eastus"

param(
    [string]$SubscriptionId,
    [string]$TenantId,
    [string]$Location = "eastus"
)

if (-not $SubscriptionId) {
    Write-Error "SubscriptionId is required."
    exit 1
}

if (-not $TenantId) {
    Write-Error "TenantId is required when deploying to a subscription in a different tenant."
    exit 1
}

# Login check
$currentSub = az account show --query id -o tsv
if ($currentSub -ne $SubscriptionId) {
    Write-Host "Setting active subscription to $SubscriptionId in tenant $TenantId..."
    az account set --subscription $SubscriptionId --tenant $TenantId
}

# Build the .NET Function
Write-Host "Building .NET Function..."
dotnet build src/AzureAutoTagging/AzureAutoTagging.csproj -c Release
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Publishing .NET Function..."
dotnet publish src/AzureAutoTagging/AzureAutoTagging.csproj -c Release -o ./publish
if ($LASTEXITCODE -ne 0) { exit 1 }

# Deploy Infrastructure
Write-Host "Deploying Infrastructure (Bicep)..."
$deploymentName = "autotagging-deploy-$(Get-Date -Format 'yyyyMMddHHmm')"
$bicepOutput = az deployment sub create --location $Location --template-file infra/main.bicep --name $deploymentName --parameters location=$Location --subscription $SubscriptionId 2>&1

# Check for Bicep errors
if ($LASTEXITCODE -ne 0) {
    Write-Error "Infrastructure deployment failed."
    Write-Host $bicepOutput
    exit 1
}

# Parse Outputs
$outputs = $bicepOutput | ConvertFrom-Json
$functionAppName = $outputs.properties.outputs.functionAppName.value
$resourceGroupName = $outputs.properties.outputs.resourceGroupName.value
$functionAppId = $outputs.properties.outputs.functionAppId.value
$functionPrincipalId = $outputs.properties.outputs.functionPrincipalId.value

Write-Host "Infrastructure deployed successfully."
Write-Host "Function App: $functionAppName"
Write-Host "Resource Group: $resourceGroupName"
Write-Host "Function Principal ID: $functionPrincipalId"

# Zip Deploy Function Code
Write-Host "Zipping and Deploying Function Code..."
Compress-Archive -Path ./publish/* -DestinationPath ./publish/func.zip -Force

az functionapp deployment source config-zip --resource-group $resourceGroupName --name $functionAppName --src ./publish/func.zip
if ($LASTEXITCODE -ne 0) { exit 1 }

# Waiting for function listing sync
Write-Host "Waiting for Function App metadata sync..."
Start-Sleep -Seconds 30

# Deploy Event Grid Subscription
Write-Host "Deploying Event Grid Subscription..."
az deployment sub create --location $Location --template-file infra/events.bicep --name "autotagging-events-deploy-$(Get-Date -Format 'yyyyMMddHHmm')" --parameters functionAppId=$functionAppId principalId=$functionPrincipalId --subscription $SubscriptionId

Write-Host "Deployment Complete!"
