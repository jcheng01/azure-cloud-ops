locals {
  required_governance_tags = [
    "Environment",
    "ManagedBy",
    "Project",
  ]

  governed_resource_groups = {
    lab        = data.azurerm_resource_group.cloudops.id
    production = data.azurerm_resource_group.cloudops_prod.id
  }
}

resource "azurerm_policy_definition" "required_tags_audit" {
  name         = "cloudops-audit-required-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "CloudOps - Audit required resource tags"
  description  = "Audits resources missing Environment, ManagedBy, or Project tags."

  metadata = jsonencode({
    category = "CloudOps Portfolio"
  })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        for tag_name in local.required_governance_tags : {
          field  = "tags['${tag_name}']"
          exists = false
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })
}

resource "azurerm_policy_definition" "allowed_locations_audit" {
  name         = "cloudops-audit-allowed-locations"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "CloudOps - Audit allowed Azure locations"
  description  = "Audits resources deployed outside East US, East US 2, or global."

  metadata = jsonencode({
    category = "CloudOps Portfolio"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "location"
          exists = true
        },
        {
          not = {
            field = "location"
            in    = ["eastus", "eastus2", "global"]
          }
        }
      ]
    }
    then = {
      effect = "Audit"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "required_tags" {
  for_each = local.governed_resource_groups

  name                 = "cloudops-tags-${each.key}"
  resource_group_id    = each.value
  policy_definition_id = azurerm_policy_definition.required_tags_audit.id
  display_name         = "CloudOps required tags audit - ${each.key}"
  description          = "Audits required CloudOps tags without blocking deployments."

  non_compliance_message {
    content = "Resources should include Environment, ManagedBy, and Project tags."
  }
}

resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  for_each = local.governed_resource_groups

  name                 = "cloudops-locations-${each.key}"
  resource_group_id    = each.value
  policy_definition_id = azurerm_policy_definition.allowed_locations_audit.id
  display_name         = "CloudOps allowed locations audit - ${each.key}"
  description          = "Audits resource locations without blocking deployments."

  non_compliance_message {
    content = "CloudOps resources should use East US, East US 2, or global."
  }
}
