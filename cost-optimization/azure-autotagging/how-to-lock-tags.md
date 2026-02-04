# How to lock tags (Prevent Deletion/Modification)

Locking specific tags (like `created-by`) to prevent them from being changed or removed by users is a common governance requirement. Since Azure Management Locks apply to the entire resource, the best tool for this granular control is **Azure Policy**.

## Solution: Azure Policy with `Deny` Effect

You can create a policy assignment that denies any write operation (CREATE/UPDATE) to a resource if it attempts to change or remove a specific tag that should be immutable.

### Policy Logic
1.  **Condition**: The resource *already* has the tag `created-by`.
2.  **Condition**: The request *change* results in the tag being missing OR having a different value.
3.  **Effect**: Deny.

### Sample Policy Definition

```json
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "tags['created-by']",
          "exists": "true"
        },
        {
          "not": {
             "field": "tags['created-by']",
             "equals": "[resource().tags['created-by']]"
          }
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

*Note: Accessing `resource()` in a Deny policy to compare with the existing state can be complex depending on Policy version support. A simpler enforcement is ensuring the tag is NOT removed (checking for existence in the request).*

## Alternative: Custom RBAC Role

You can create a custom RBAC role that has `write` permissions on resources but includes a `notActions` or simply lacks the permission for `Microsoft.Resources/tags/write` or `*/write` on the tags endpoint, but usually, tag updates are part of the main resource `write` action, so separating them is difficult without using a specific "Tag Contributor" model reversed.

**Recommendation**: Use Azure Policy to audit or deny changes to these specific governance tags.
