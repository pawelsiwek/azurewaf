# Azure Auto-Tagging Function

## Overview

This Azure Function automatically tags Azure resources based on predefined rules to support cost optimization efforts. It runs on a scheduled basis (daily at 2 AM UTC) and applies consistent tags to all resources in a subscription.

## Features

- **Automated Tagging**: Automatically applies standardized tags to Azure resources
- **Cost Tracking**: Helps organize and track costs by applying CostCenter and Environment tags
- **Compliance**: Ensures all resources are properly tagged for governance
- **Non-Destructive**: Preserves existing tags while adding new ones
- **Configurable**: Supports custom tags through environment variables

## Architecture

The solution consists of:

1. **Azure Function (Python)**: Timer-triggered function that scans and tags resources
2. **Managed Identity**: Uses System-assigned identity with Contributor role for tagging
3. **Application Insights**: Monitoring and logging
4. **Storage Account**: Required for Azure Functions runtime

## Default Tags Applied

| Tag Name | Description | Example Value |
|----------|-------------|---------------|
| `AutoTagged` | Indicates resource was tagged by this function | `true` |
| `TaggedDate` | Date when resource was tagged | `2026-02-04` |
| `ManagedBy` | Identifies the management tool | `AzureFunction` |
| `Environment` | Resource environment | `Production` / `Development` |
| `CostCenter` | Cost allocation | `IT-Operations` |

## Prerequisites

- Azure subscription
- Azure CLI installed
- Contributor access to the subscription
- `jq` command-line tool (for deployment script)

## Deployment

### Option 1: Using the Deployment Script

1. Navigate to the deployment directory:
   ```bash
   cd cost-optimization/azure-autotagging
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deployment/deploy.sh
   ```

3. Run the deployment:
   ```bash
   export SUBSCRIPTION_ID="your-subscription-id"
   export RESOURCE_GROUP_NAME="rg-autotagging-prod"
   export LOCATION="eastus"
   ./deployment/deploy.sh
   ```

### Option 2: Manual Deployment

1. Create a resource group:
   ```bash
   az group create --name rg-autotagging-prod --location eastus
   ```

2. Deploy the Bicep template:
   ```bash
   az deployment group create \
     --resource-group rg-autotagging-prod \
     --template-file deployment/main.bicep \
     --parameters azureSubscriptionId="your-subscription-id"
   ```

3. Get the Function App name and Principal ID from outputs:
   ```bash
   FUNCTION_APP_NAME=$(az deployment group show \
     --resource-group rg-autotagging-prod \
     --name main \
     --query properties.outputs.functionAppName.value -o tsv)
   
   PRINCIPAL_ID=$(az deployment group show \
     --resource-group rg-autotagging-prod \
     --name main \
     --query properties.outputs.functionAppPrincipalId.value -o tsv)
   ```

4. Assign Contributor role:
   ```bash
   az role assignment create \
     --assignee $PRINCIPAL_ID \
     --role "Contributor" \
     --scope "/subscriptions/your-subscription-id"
   ```

5. Deploy function code:
   ```bash
   cd function
   zip -r ../function.zip .
   cd ..
   
   az functionapp deployment source config-zip \
     --resource-group rg-autotagging-prod \
     --name $FUNCTION_APP_NAME \
     --src function.zip
   ```

## Configuration

### Environment Variables

The function can be configured through environment variables (set in the Function App's Application Settings):

- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID to scan (required)
- `ENVIRONMENT`: Environment name (e.g., Production, Development)
- `COST_CENTER`: Cost center for billing purposes

### Timer Schedule

The function is configured to run daily at 2 AM UTC. To modify the schedule, edit `function/function.json`:

```json
{
  "schedule": "0 0 2 * * *"
}
```

Schedule format is a CRON expression: `{second} {minute} {hour} {day} {month} {day-of-week}`

Examples:
- Every hour: `0 0 * * * *`
- Every 6 hours: `0 0 */6 * * *`
- Weekly on Monday at 3 AM: `0 0 3 * * 1`

## Local Development

1. Install Azure Functions Core Tools:
   ```bash
   npm install -g azure-functions-core-tools@4
   ```

2. Install Python dependencies:
   ```bash
   cd function
   pip install -r requirements.txt
   ```

3. Update `local.settings.json` with your subscription ID:
   ```json
   {
     "Values": {
       "AZURE_SUBSCRIPTION_ID": "your-subscription-id"
     }
   }
   ```

4. Run locally:
   ```bash
   func start
   ```

## Monitoring

### View Logs

1. Using Azure Portal:
   - Navigate to Function App → Functions → AutoTagging → Monitor
   - View execution history and logs

2. Using Azure CLI:
   ```bash
   az functionapp log tail \
     --resource-group rg-autotagging-prod \
     --name your-function-app-name
   ```

3. Using Application Insights:
   ```bash
   az monitor app-insights query \
     --app your-app-insights-name \
     --analytics-query "traces | where message contains 'Auto-tagging'"
   ```

## Cost Optimization Benefits

1. **Resource Tracking**: Easily identify resources by environment and cost center
2. **Cost Allocation**: Generate cost reports grouped by tags
3. **Budget Alerts**: Set up alerts based on tag-based cost groups
4. **Orphaned Resources**: Identify untagged or unmanaged resources
5. **Compliance**: Ensure tagging policy compliance

## Security Considerations

- Uses Managed Identity (no credentials in code)
- HTTPS only for all communications
- TLS 1.2 minimum
- Storage account with public access disabled
- Function App with FTPS disabled

## Troubleshooting

### Function not tagging resources

1. Check if Managed Identity has proper permissions:
   ```bash
   az role assignment list --assignee $PRINCIPAL_ID
   ```

2. Verify subscription ID is correct in Function App settings

3. Check Application Insights logs for errors

### Permission Denied errors

Ensure the Function App's Managed Identity has Contributor role at the subscription level.

### Function not triggering

1. Verify the timer schedule in `function.json`
2. Check Function App is running (not stopped)
3. Review Function execution history in Azure Portal

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions, please use the GitHub issue tracker.
