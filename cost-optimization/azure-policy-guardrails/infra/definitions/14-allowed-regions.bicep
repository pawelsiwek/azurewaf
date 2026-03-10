// Policy #14 — Allowed Azure regions whitelist
// Effect: deny if resource location NOT in approved list
//
// Included: all public regions priced at or below the global average (~1.0–1.10× vs. East US baseline).
// Excluded regions (above-average cost):
//   Brazil South / Southeast      — ~1.5–1.8× (local import duties & taxes)
//   Australia East/Southeast/Central 1&2  — ~1.25–1.35×
//   New Zealand North              — ~1.28×
//   South Africa North / West      — ~1.30–1.35×
//   Switzerland North / West       — ~1.15–1.20×
//   Japan East / West              — ~1.12–1.17×
//   Qatar Central                  — ~1.15×
//   Israel Central                 — ~1.12×
//   Chile Central                  — ~1.12×
//   Saudi Arabia East              — ~1.10–1.12×
//
// Sovereign / government regions (US Gov, DoD, China, Germany Sovereign) are intentionally omitted.
targetScope = 'subscription'

resource policyDef 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'waf-cost-14-allowed-regions'
  properties: {
    displayName: '[WAF Cost] Allowed Azure regions whitelist'
    description: 'Denies resources deployed in regions not on the approved list. Includes all Azure public regions priced at or below the global average. Excluded: Brazil (~1.5-1.8×), Australia/NZ (~1.3×), South Africa (~1.32×), Switzerland (~1.17×), Japan (~1.15×), Qatar/Israel/Chile/Saudi Arabia (>1.1×). Prevents accidental deployment to expensive regions and unexpected cross-region data transfer charges. Global/regional services (Azure AD, Traffic Manager) are excluded via mode=Indexed.'
    policyType: 'Custom'
    mode: 'Indexed'
    metadata: {
      category: 'Cost Optimization'
      version: '2.0.0'
    }
    parameters: {
      allowedLocations: {
        type: 'Array'
        metadata: {
          displayName: 'Allowed locations'
          description: 'List of approved Azure region names (all regions priced at or below global average). Adjust as needed.'
          strongType: 'location'
        }
        defaultValue: [
          // ── Americas ──────────────────────────────────────────
          'eastus'
          'eastus2'
          'westus'
          'westus2'
          'westus3'
          'centralus'
          'northcentralus'
          'southcentralus'
          'westcentralus'
          'canadacentral'
          'canadaeast'
          'mexicocentral'
          // ── Europe ────────────────────────────────────────────
          'westeurope'
          'northeurope'
          'uksouth'
          'ukwest'
          'francecentral'
          'germanywestcentral'
          'norwayeast'
          'swedencentral'
          'polandcentral'
          'italynorth'
          'spaincentral'
          'austriaeast'
          'belgiumcentral'
          'denmarkeast'
          'finlandcentral'
          // ── Asia Pacific ──────────────────────────────────────
          'southeastasia'
          'eastasia'
          'centralindia'
          'southindia'
          'westindia'
          'koreacentral'
          'koreasouth'
          'indonesiacentral'
          'malaysiawest'
          // ── Middle East ───────────────────────────────────────
          'uaenorth'
          // ── Global (non-regional services) ───────────────────
          'global'
        ]
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
        allOf: [
          {
            field: 'location'
            notIn: '[parameters(\'allowedLocations\')]'
          }
          {
            field: 'location'
            notEquals: 'global'
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
