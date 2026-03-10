# Azure WAF Cost Optimization Guardrails

A production-ready Azure Policy initiative containing **25 custom policy definitions** aligned with the [Azure Well-Architected Framework — Cost Optimization pillar](https://learn.microsoft.com/azure/well-architected/cost-optimization/). Designed for the **AzureDay 2026** conference presentation: *"Azure WAF Cost Optimization in Practice"*.

## Policy inventory

| # | Policy | Effect | Category |
|---|--------|--------|----------|
| 01 | Require mandatory cost tags (Environment, CostCenter, Owner, Project) | Deny | Tagging |
| 02 | Require ExpirationDate tag on non-prod resources | Audit | Tagging |
| 03 | Deny resource groups without cost tags | Deny | Tagging |
| 04 | Require LastCostReview tag on resources | Audit | Tagging |
| 05 | Allowed VM SKUs whitelist (blocks M/GPU/HPC series) | Deny | Compute |
| 06 | Enforce auto-shutdown on dev/test VMs (19:00 UTC) | DeployIfNotExists | Compute |
| 07 | Allowed App Service Plan tiers whitelist (blocks Premium v2/v3, Isolated) | Deny | Compute |
| 08 | Enforce autoscaling on Standard+ App Service Plans | AuditIfNotExists | Compute |
| 09 | Allowed AKS node pool VM sizes whitelist (blocks GPU/HPC) | Deny | Compute |
| 10 | Max instances/replicas limit on App Service, Container Apps, Functions, ACI | Deny | Compute |
| 11 | Deny AI Foundry / Azure OpenAI Provisioned Throughput (PTU) | Deny | AI |
| 12 | Allowed Storage Account SKUs whitelist in non-prod (blocks Premium) | Deny | Storage |
| 13 | Require Blob Lifecycle Management Policy (Cool/Cold/Archive tiering) | AuditIfNotExists | Storage |
| 14 | Audit unattached managed disks | Audit | Storage |
| 15 | Restrict Log Analytics Workspace data retention (max N days) | Deny | Storage |
| 16 | Audit unused (unassociated) static public IP addresses | Audit | Networking |
| 17 | Allowed Azure regions whitelist | Deny | Networking |
| 18 | Audit idle costly network services in non-prod (Bastion, Firewall, NAT GW) | Audit | Networking |
| 19 | Allowed SQL Database tiers whitelist in non-prod (blocks Business Critical) | Deny | Database |
| 20 | Allowed Azure Cache for Redis tiers whitelist in non-prod (blocks Premium) | Deny | Database |
| 21 | Require at least one budget on subscription | AuditIfNotExists | Budget |
| 22 | Require alert notifications on subscription budgets | Audit | Budget |
| 23 | Deploy budget alert per resource group (auto-deployed, 80%+100%) | DeployIfNotExists | Budget |
| 25 | Audit deallocated VMs in non-production environments | Audit | Compute |
| 26 | Audit Traffic Manager profiles without multi-region backends | Audit | Networking |

## Repository structure

```
azure-policy-guardrails/
├── deploy.ps1                          # One-command deployment script
└── infra/
    ├── initiative.bicep                # Aggregates all 25 definitions into 1 initiative
    ├── definitions/
    │   ├── 01-require-cost-tags.bicep
    │   ├── 02-require-expiration-tag.bicep
    │   ├── 03-deny-rg-without-cost-tags.bicep
    │   ├── 04-require-last-cost-review-tag.bicep
    │   ├── 05-allowed-vm-skus.bicep
    │   ├── 06-enforce-vm-autoshutdown.bicep
    │   ├── 07-allowed-appservice-plan-tiers.bicep
    │   ├── 08-enforce-appservice-autoscaling.bicep
    │   ├── 09-allowed-aks-node-vm-sizes.bicep
    │   ├── 10-max-instances-limit.bicep
    │   ├── 11-deny-foundry-provisioned-throughput.bicep
    │   ├── 12-allowed-storage-skus.bicep
    │   ├── 13-require-blob-lifecycle-policy.bicep
    │   ├── 14-audit-unattached-disks.bicep
    │   ├── 15-restrict-loganalytics-retention.bicep
    │   ├── 16-audit-unused-public-ips.bicep
    │   ├── 17-allowed-regions.bicep
    │   ├── 18-audit-idle-network-services.bicep
    │   ├── 19-allowed-sql-tiers.bicep
    │   ├── 20-allowed-redis-tiers.bicep
    │   ├── 21-require-subscription-budget.bicep
    │   ├── 22-require-budget-alerts.bicep
    │   ├── 23-deploy-rg-budget-alert.bicep
    │   ├── 25-audit-deallocated-vms.bicep
    │   └── 26-audit-trafficmanager-single-region.bicep
    └── assignments/
        ├── assignment.bicep            # Policy assignment with managed identity
        └── assignment.bicepparam       # Parameters — edit before deploying
```

## Quick start

### Prerequisites

- Azure CLI ≥ 2.50
- Bicep CLI ≥ 0.26 (`az bicep install`)
- Role: **Resource Policy Contributor** or **Owner** on target subscription

### Recommended rollout strategy

1. **Assessment phase** — deploy with `-AuditMode` flag, review compliance report
2. **Exemption phase** — create exemptions for legitimate exceptions
3. **Enforcement phase** — redeploy without `-AuditMode` to enable Deny effects

```powershell
# Step 1 — Assessment (audit only, no deny blocks)
./deploy.ps1 -AlertEmail "cost@yourcompany.com" -AuditMode

# Step 2 — Review compliance in Portal
# https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Compliance

# Step 3 — Enforce after reviewing non-compliant resources
./deploy.ps1 -AlertEmail "cost@yourcompany.com"
```

### Custom parameters

```powershell
./deploy.ps1 `
  -AlertEmail        "cost@yourcompany.com" `
  -RgBudgetUSD       1000 `
  -MaxInstances      20 `
  -MaxLogRetentionDays 60 `
  -AllowedLocations  "westeurope,northeurope,eastus"
```

### Manual deployment (initiative then assignment)

```bash
# 1. Deploy definitions + initiative
az deployment sub create \
  --location westeurope \
  --template-file infra/initiative.bicep

# 2. Get initiative ID from output
INITIATIVE_ID=$(az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs.initiativeId.value -o tsv)

# 3. Edit assignments/assignment.bicepparam (set initiativeId + alertEmailAddress)

# 4. Deploy assignment
az deployment sub create \
  --location westeurope \
  --template-file infra/assignments/assignment.bicep \
  --parameters infra/assignments/assignment.bicepparam
```

## Creating policy exemptions

For workloads that legitimately need resources blocked by a policy:

```bash
az policy exemption create \
  --name "allow-gpu-for-ml-team" \
  --display-name "GPU VMs allowed for ML workloads" \
  --policy-assignment <assignment-id> \
  --policy-definition-reference-id "waf-cost-09" \
  --scope "/subscriptions/<sub>/resourceGroups/rg-ml-prod" \
  --exemption-category "Waiver" \
  --description "ML team requires NC-series nodes for training workloads"
```

## Notes on policy limitations

| Policy | Limitation |
|--------|-----------|
| **#04** LastCostReview date staleness | Azure Policy cannot compare date tags to "today minus N days". Complement with an Azure Automation runbook or Logic App that scans tag values and sets `LastCostReviewStale=true`. |
| **#25** Deallocated VMs duration | Policy reflects current `powerState` only — it cannot determine how long a VM has been stopped. For duration-based detection: deploy an EventGrid rule that sets `DeallocatedSince=<ISO date>` tag on VM deallocate event, then scan with Automation. |
| **#26** Active-passive detection | Heuristic based on Traffic Manager endpoint count. False positives possible for valid single-backend configurations. Review flagged resources manually. |
