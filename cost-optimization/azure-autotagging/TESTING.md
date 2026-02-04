# Azure Auto-Tagging - Testing Guide

## Local Testing

To test the function locally without deploying to Azure:

### Preparation

1. Log in to Azure CLI:
```powershell
az login --tenant <tenant-id>
```

2. Set the appropriate subscription:
```powershell
az account set --subscription <subscription-id>
```

### Running the test

```powershell
# Enable debug mode
$env:DEBUG_MODE = "true"

# Run test (change parameters to your resources)
dotnet run --project src/AzureAutoTagging/IntegrationTest.cs -- `
    <subscription-id> `
    rg-autotagging `
    test123123123321321
```

### Verification

Check if tags were applied:
```powershell
az storage account show --name test123123123321321 --resource-group rg-autotagging --query tags
```

The following tags should appear:
- `created-by`: user name
- `modified-by`: user name

## Debug Mode

The function supports an extended debug mode. To enable it:

### In Azure Function App:
```powershell
az functionapp config appsettings set `
    --name <function-app-name> `
    --resource-group rg-autotagging `
    --settings "DEBUG_MODE=true"
```

### Locally:
```powershell
$env:DEBUG_MODE = "true"
```

In debug mode, the function logs:
- Full Event Grid payload
- EventType and Subject
- Available claims keys
- Current resource tags
- Tags API URL
- Token expiration
- Payload sent to API
- Response status code

## Deployment and Test

To deploy a new version and test:

```powershell
# Deploy with TenantId parameter
.\deploy.ps1 -SubscriptionId <subscription-id> `
             -TenantId <tenant-id>

# Modify resource to trigger event
az storage account update --name test123123123321321 `
    --tags test-timestamp="$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"

# Wait 15 seconds
Start-Sleep -Seconds 15

# Check tags
az storage account show --name test123123123321321 --query tags -o json
```

## Monitoring

### Application Insights Queries

Check function logs:
```kusto
traces 
| where timestamp > ago(1h)
| where message contains "Processing event" or message contains "[DEBUG]"
| order by timestamp desc
| project timestamp, message
```

Check errors:
```kusto
exceptions 
| where timestamp > ago(1h)
| order by timestamp desc
| project timestamp, type, outerMessage, problemId
```

### Event Grid Metrics

Check if events are delivered:
```powershell
az monitor metrics list `
    --resource /subscriptions/<subscription-id> `
    --metric-names "DeliverySuccessCount,DeliveryFailCount" `
    --start-time (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ss") `
    --interval PT5M
```

## Permissions

The function requires the following roles at the subscription level:
- **Reader** - to read resources
- **Tag Contributor** - to modify tags

Check permissions:
```powershell
$principalId = "<principal-id>"  # Function principal ID
az role assignment list --assignee $principalId `
    --scope /subscriptions/<subscription-id> `
    --query "[].{role:roleDefinitionName}" -o table
```

## Troubleshooting

### Problem: Tags are not applied

1. Check if the function has Reader and Tag Contributor permissions
2. Enable DEBUG_MODE and check logs
3. Check if Event Grid delivers events (check metrics)
4. Check exceptions in Application Insights

### Problem: 403 Authorization errors

The function needs time for permission propagation (up to 5 minutes). Wait and try again.

### Problem: ServicePrincipal is not recognized

Funkcja wspiera zarówno user principals jak i service principals. Dla SP zwraca format `ServicePrincipal:{appId}`.
