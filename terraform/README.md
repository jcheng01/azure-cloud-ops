# Terraform

This directory manages the existing CloudOps network plus the public application platform, identity, observability, governance, and cost controls.

## State and ownership

- The `azurerm` backend stores state in Azure Blob Storage and uses Azure CLI authentication.
- Existing networking, security rules, and the Static Web App were imported.
- Function, storage, service plan, monitoring, alerts, policies, budget, and RBAC are Terraform-managed.
- The Static Web App GitHub connection stays portal-managed so its token never enters configuration or state.
- Local state, saved plans, and personal variable files must not be committed.

## Commands

```powershell
$env:TF_VAR_subscription_id = az account show --query id --output tsv
$env:TF_VAR_alert_email_address = "your-email@example.com"

terraform init
terraform fmt
terraform validate
terraform plan "-out=cloudops.tfplan"
terraform apply "cloudops.tfplan"
terraform plan
```

Always inspect the saved plan. A healthy post-apply plan reports no changes.
