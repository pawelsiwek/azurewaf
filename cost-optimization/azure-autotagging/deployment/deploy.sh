#!/bin/bash

# Azure Auto-Tagging Function Deployment Script
# This script deploys the auto-tagging Azure Function and assigns necessary permissions

set -e

# Variables
RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME:-rg-autotagging-prod}"
LOCATION="${LOCATION:-eastus}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Azure Auto-Tagging Function Deployment${NC}"
echo "========================================"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Please login to Azure${NC}"
    az login
fi

# Get subscription ID if not provided
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    echo -e "${YELLOW}Using subscription: $SUBSCRIPTION_ID${NC}"
fi

# Set the subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Create resource group if it doesn't exist
echo -e "${GREEN}Creating resource group: $RESOURCE_GROUP_NAME${NC}"
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"

# Deploy Bicep template
echo -e "${GREEN}Deploying Azure Function infrastructure...${NC}"
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file deployment/main.bicep \
    --parameters azureSubscriptionId="$SUBSCRIPTION_ID" \
    --query properties.outputs \
    -o json)

# Extract outputs
FUNCTION_APP_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.functionAppName.value')
PRINCIPAL_ID=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.functionAppPrincipalId.value')

echo -e "${GREEN}Function App Name: $FUNCTION_APP_NAME${NC}"
echo -e "${GREEN}Principal ID: $PRINCIPAL_ID${NC}"

# Assign Contributor role to Function App's managed identity
echo -e "${GREEN}Assigning permissions to Function App...${NC}"
az role assignment create \
    --assignee "$PRINCIPAL_ID" \
    --role "Contributor" \
    --scope "/subscriptions/$SUBSCRIPTION_ID"

echo -e "${GREEN}Waiting for role assignment to propagate...${NC}"
sleep 30

# Deploy function code
echo -e "${GREEN}Deploying function code...${NC}"
cd function
zip -r ../function.zip .
cd ..

az functionapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$FUNCTION_APP_NAME" \
    --src function.zip

rm function.zip

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "========================================"
echo -e "${GREEN}Function App URL: https://${FUNCTION_APP_NAME}.azurewebsites.net${NC}"
echo -e "${YELLOW}Note: The function is configured to run daily at 2 AM UTC${NC}"
