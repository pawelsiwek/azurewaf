# Local Integration Test Script
# Usage: .\test-local.ps1 [-SubscriptionId <id>] [-ResourceGroup <rg>] [-ResourceName <name>]

param(
    [string]$SubscriptionId = "<subscription-id>",
    [string]$ResourceGroup = "rg-autotagging",
    [string]$ResourceName = "test"
)

Write-Host "=== Azure Auto-Tagging Local Test ===" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI login
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
$account = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Not logged in to Azure CLI" -ForegroundColor Red
    Write-Host "Please run: az login --tenant <tenant-id>" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Azure CLI authenticated" -ForegroundColor Green
Write-Host ""

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet build src/AzureAutoTagging/AzureAutoTagging.csproj -c Debug
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Build successful" -ForegroundColor Green
Write-Host ""

# Run the integration test
Write-Host "Running integration test..." -ForegroundColor Yellow
Write-Host "Note: The function will attempt to update tags on the actual Azure resource." -ForegroundColor Yellow
Write-Host ""

$env:DEBUG_MODE = "true"

# Run via dotnet run passing the integration test flag
$output = dotnet run --project src/AzureAutoTagging/AzureAutoTagging.csproj -- --integration-test $SubscriptionId $ResourceGroup $ResourceName | Out-String

Write-Host $output

if ($output -match "Test completed successfully") {
    Write-Host ""
    Write-Host "=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "[OK] Integration test completed" -ForegroundColor Green
    Write-Host ""
    Write-Host "To verify tags were applied:" -ForegroundColor Yellow
    Write-Host "  az storage account show --name $ResourceName --resource-group $ResourceGroup --query tags" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "[X] Integration test failed" -ForegroundColor Red
    exit 1
}
