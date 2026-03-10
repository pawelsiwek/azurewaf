// Policy #08 — Max concurrency/instances limit on App Service, Container Apps, Functions, ACI
// Effect: deny — prevents uncontrolled horizontal scale-out that can cause bill shock
// Covers: App Service Plan maxBurst, Container Apps maxReplicas,
//         Function App functionAppScaleLimit, Container Instances count
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-08-max-instances-limit'
  properties: {
    displayName: '[WAF Cost] Max instances/replicas limit on scalable compute resources'
    description: 'Denies creation or update of App Service Plans, Container Apps, Function Apps or Container Instances that set max scale beyond the approved limit. A misconfigured scaling rule with no upper bound can multiply costs by 10x within minutes. Use policy exemption for high-traffic production workloads requiring higher limits.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '1.0.0'
    }
    parameters: {
      maxAllowedInstances: {
        type: 'Integer'
        metadata: {
          displayName: 'Maximum allowed instances / replicas'
          description: 'Upper bound for any horizontal scale setting. Resources requesting more require a policy exemption.'
        }
        defaultValue: 10
      }
      effect: {
        type: 'String'
        metadata: {
          displayName: 'Effect'
        }
        allowedValues: [
          'deny'
          'audit'
          'disabled'
        ]
        defaultValue: 'deny'
      }
    }
    policyRule: {
      if: {
        anyOf: [
          // App Service Plan — maximum elastic worker count (Elastic Premium / Consumption)
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Web/serverfarms'
              }
              {
                field: 'Microsoft.Web/serverfarms/maximumElasticWorkerCount'
                greater: '[parameters(\'maxAllowedInstances\')]'
              }
            ]
          }
          // Container Apps — max replicas on scale rules
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.App/containerApps'
              }
              {
                field: 'Microsoft.App/containerApps/template.scale.maxReplicas'
                greater: '[parameters(\'maxAllowedInstances\')]'
              }
            ]
          }
          // Azure Functions — site-level scale limit
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.Web/sites'
              }
              {
                field: 'kind'
                contains: 'functionapp'
              }
              {
                field: 'Microsoft.Web/sites/siteConfig.functionAppScaleLimit'
                greater: '[parameters(\'maxAllowedInstances\')]'
              }
            ]
          }
          // Azure Container Instances — group count
          {
            allOf: [
              {
                field: 'type'
                equals: 'Microsoft.ContainerInstance/containerGroups'
              }
              {
                count: {
                  field: 'Microsoft.ContainerInstance/containerGroups/containers[*]'
                }
                greater: '[parameters(\'maxAllowedInstances\')]'
              }
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

output policyDefinitionId string = policyDef.id
output policyDefinitionName string = policyDef.name
