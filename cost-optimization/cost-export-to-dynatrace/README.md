# Azure Cost Export to Dynatrace

This Azure Function automatically processes Azure Cost Management exports (CSV files) stored in an Azure Blob Storage container and ingests them into Dynatrace via the Log Ingestion API v2.

## Features
- **Blob Trigger**: Automatically triggers when a new Cost Export CSV file is created or updated.
- **Dynatrace Integration**: Parses the CSV data and sends it as structured JSON logs to Dynatrace.
- **Secure**: Uses Managed Identity to access the Cost Export storage account (even if public access is disabled, provided "Trusted Microsoft Services" exception is allowed or VNet integration is used).
- **Scalable**: Processes large CSV files in streams and sends logs in batches.

## Prerequisites
1.  **Azure Subscription**: To host the Function App.
2.  **Cost Export**: Configured to export to an Azure Storage Blob container (e.g., `exports`).
3.  **Dynatrace Environment**: A valid URL (e.g., `https://<env>.live.dynatrace.com`) and an API Token with `logs.ingest` (Ingest Logs) permission.

## Deployment

1.  Open PowerShell.
2.  Run the deployment script:

```powershell
.\deploy.ps1 `
  -SubscriptionId "<your-subscription-id>" `
  -ResourceGroupName "<target-resource-group>" `
  -DynatraceUrl "https://<env>.live.dynatrace.com/api/v2/logs/ingest" `
  -DynatraceToken "<your-api-token>" `
  -CostExportStorageAccountName "<storage-account-name-with-exports>" `
  -CostExportContainerName "exports"
```

3.  **Post-Deployment Step (Permissions)**:
    The deployed Function App uses a System Assigned Managed Identity. You **must** grant this identity permission to read the Cost Export blobs.
    
    The script will output the **Principal ID** of the new Function App. Run the following command to assign the role:

    ```powershell
    # Assign 'Storage Blob Data Reader' role
    az role assignment create `
      --assignee "<PRINCIPAL_ID_FROM_OUTPUT>" `
      --role "Storage Blob Data Reader" `
      --scope "/subscriptions/<sub-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-account-name>"
    ```

    *Without this step, the Function App will log 403 Forbidden errors.*

## Processing Historical Data

By default, the function only processes **new** or **modified** files. To process existing Cost Export files (e.g., from the last week), run the included helper script:

```powershell
.\reprocess-blobs.ps1
```

This script will "touch" the blobs (update metadata), causing the Blob Trigger to fire and ingest the data into Dynatrace.

## Network Security Notes

If your Cost Export storage account has **disabled public access**, ensure that:
1.  **Trusted Microsoft Services** exception is enabled on the Storage Account networking settings. This often allows the Function App to access it via Managed Identity.
2.  Alternatively, configure **VNet Integration** for the Function App to access the Storage Account via Private Endpoint (requires Premium Plan or Standard App Service Plan, usually not supported on Consumption Y1 plan).

For this demo, enabling "Allow Azure services on the trusted services list to access this storage account" is recommended if using Consumption Plan.
