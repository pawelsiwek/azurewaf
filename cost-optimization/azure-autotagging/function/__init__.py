"""
Azure Function for Auto-Tagging Resources
This function automatically tags Azure resources based on predefined rules
for cost optimization purposes.
"""

import logging
import json
import os
from datetime import datetime
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient


def main(mytimer: func.TimerRequest) -> None:
    """
    Main function triggered by timer to auto-tag Azure resources.
    
    Args:
        mytimer: Timer trigger input
    """
    current_time = datetime.utcnow()
    utc_timestamp = current_time.isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info('Python timer trigger function started at %s', utc_timestamp)

    try:
        # Get configuration from environment variables
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        if not subscription_id:
            logging.error('AZURE_SUBSCRIPTION_ID environment variable not set')
            return

        # Initialize Azure credentials and client
        credential = DefaultAzureCredential()
        resource_client = ResourceManagementClient(credential, subscription_id)

        # Define default tags
        default_tags = {
            'AutoTagged': 'true',
            'TaggedDate': current_time.strftime('%Y-%m-%d'),
            'ManagedBy': 'AzureFunction',
            'Environment': os.environ.get('ENVIRONMENT', 'Production'),
            'CostCenter': os.environ.get('COST_CENTER', 'Default')
        }

        # Get all resources in the subscription
        resources = list(resource_client.resources.list())
        logging.info(f'Found {len(resources)} resources to process')

        tagged_count = 0
        skipped_count = 0

        for resource in resources:
            try:
                # Get current tags
                current_tags = resource.tags or {}
                
                # Skip if already tagged by this function
                if current_tags.get('AutoTagged') == 'true':
                    skipped_count += 1
                    continue

                # Merge default tags with existing tags (existing tags take precedence)
                new_tags = {**default_tags, **current_tags}

                # Update resource with new tags
                resource_group = resource.id.split('/')[4]
                resource_type = resource.type
                resource_name = resource.name

                logging.info(f'Tagging resource: {resource_name} in {resource_group}')

                # Update the resource
                resource_client.resources.begin_update_by_id(
                    resource.id,
                    {
                        'tags': new_tags
                    },
                    api_version=_get_api_version(resource_type)
                )

                tagged_count += 1

            except Exception as e:
                logging.error(f'Error tagging resource {resource.name}: {str(e)}')
                continue

        logging.info(f'Auto-tagging completed. Tagged: {tagged_count}, Skipped: {skipped_count}')

    except Exception as e:
        logging.error(f'Error in auto-tagging function: {str(e)}')
        raise


def _get_api_version(resource_type: str) -> str:
    """
    Get the appropriate API version for a resource type.
    
    Args:
        resource_type: The resource type
        
    Returns:
        API version string
        
    Note:
        API versions should be reviewed and updated periodically to ensure
        compatibility with the latest Azure resource provider versions.
        Last updated: 2026-02-04
    """
    # Map of common resource types to API versions
    api_versions = {
        'Microsoft.Compute/virtualMachines': '2023-03-01',
        'Microsoft.Storage/storageAccounts': '2023-01-01',
        'Microsoft.Web/sites': '2022-09-01',
        'Microsoft.Sql/servers': '2022-05-01-preview',
        'Microsoft.Network/virtualNetworks': '2023-04-01',
        'Microsoft.KeyVault/vaults': '2023-02-01',
    }
    
    return api_versions.get(resource_type, '2023-07-01')
