# Azure Auto-Tagging Function

This solution provides an automated mechanism to tag Azure resources immediately upon creation or modification. It is designed to assist with **Cost Optimization** and governance by ensuring every resource allows for ownership tracking.

## 🏷️ Features

The function automatically appends the following tags to resources triggered by write events:

*   `created-by`: The service principal or user email that initiated the creation.
*   `modified-by`: The service principal or user email that performed the last modification.

## 🏗️ Architecture

This solution employs a serverless, event-driven architecture to ensure low latency and minimal cost.
*   **Trigger**: Event Grid System Topic subscribed to `Microsoft.Resources.ResourceWriteSuccess` events at the Subscription or Resource Group level.
*   **Compute**: Azure Function (running on .NET 8).
*   **Identity**: System-Assigned Managed Identity used to authenticate against Azure Resource Manager.

## 🚀 Deployment

### Prerequisites

*   **Azure Subscription**: You need an active Azure subscription.
*   **Permissions**: Owner or User Access Administrator to assign roles to the Managed Identity.
*   **Tools**: PowerShell, Azure CLI, .NET 8 SDK.

### Deploy script

The repository includes a helper script `deploy.ps1` that orchestrates the build and deployment process.

```powershell
.\deploy.ps1 -SubscriptionId "<your-subscription-id>" -TenantId "<your-tenant-id>" -Location "<location>"
```

**What the script does:**
1.  **Builds**: Compiles the .NET 8 Function project.
2.  **Infrastructure**: Provision resources (Function App, Storage, Event Grid) using **Bicep**.
3.  **Publish**: Deploys the function code to Azure.

## 🔐 Required Permissions

For the function to operate correctly, its Managed Identity requires specific RBAC roles on the scope it manages (Subscription or Resource Group):

| Role | Purpose |
| :--- | :--- |
| **Reader** | Required to read the current state of a resource and its existing tags. |
| **Tag Contributor** | Required to add or update tags on the resource without modifying the resource itself. |

## 📂 Project Structure

*   `src/`: Contains the .NET Event Grid Trigger Function code.
*   `infra/`: Contains Bicep files for Infrastructure as Code (IaC).
*   `deploy.ps1`: Deployment automation script.
