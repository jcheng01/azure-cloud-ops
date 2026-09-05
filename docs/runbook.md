# Operations runbook

## Prerequisites

- Azure CLI authenticated with `az login`
- Terraform and Azure Functions Core Tools
- Node.js 22
- Access to the Azure subscription and GitHub repository

## Apply infrastructure changes

```powershell
Set-Location .\terraform

$env:TF_VAR_subscription_id = az account show --query id --output tsv
$env:TF_VAR_alert_email_address = "your-email@example.com"

terraform init
terraform fmt
terraform validate
Remove-Item .\cloudops.tfplan -ErrorAction SilentlyContinue
terraform plan "-out=cloudops.tfplan"
terraform apply "cloudops.tfplan"
terraform plan
```

The healthy final result is `No changes. Your infrastructure matches the configuration.`

## Validate the API locally

Run from `api/`:

```powershell
$env:AZURE_SUBSCRIPTION_ID = az account show --query id --output tsv
$env:RESOURCE_GROUP_NAME = "rg-cloudops-lab"
$env:PRODUCTION_RESOURCE_GROUP_NAME = "rg-azure-cloudops-prod"
$env:FUNCTION_RESOURCE_ID = "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/rg-azure-cloudops-prod/providers/Microsoft.Web/sites/func-azure-cloudops-jcheng01"
$env:MONTHLY_BUDGET = "5"

npm install
npm test
func start --javascript
```

In a second terminal:

```powershell
"overview","networking","security","monitoring","governance" |
  ForEach-Object {
    Invoke-RestMethod "http://localhost:7071/api/$_" |
      ConvertTo-Json -Depth 10
  }
```

If 7071 is occupied, stop the existing host or use `func start --javascript --port 7072`.

## Verify production

```powershell
$functionHost = az resource show `
  --name "func-azure-cloudops-jcheng01" `
  --resource-group "rg-azure-cloudops-prod" `
  --resource-type "Microsoft.Web/sites" `
  --query "properties.defaultHostName" `
  --output tsv

"overview","networking","security","monitoring","governance" |
  ForEach-Object {
    Invoke-RestMethod "https://$functionHost/api/$_" |
      ConvertTo-Json -Depth 10
  }
```

Dashboard: https://wonderful-bush-0b51e040f.6.azurestaticapps.net

## Inspect operations controls

```powershell
az monitor action-group show `
  --name ag-azure-cloudops `
  --resource-group rg-azure-cloudops-prod `
  --output table

az monitor metrics alert show `
  --name alert-function-http-5xx `
  --resource-group rg-azure-cloudops-prod `
  --output table
```

Use `monitoring/function-observability.kql` from the Log Analytics workspace.

## Rollback

Application rollback uses a normal revert:

```powershell
git log --oneline -10
git revert <commit-sha>
git push origin main
```

For infrastructure, revert the Terraform commit, generate a new plan, and inspect every destroy or replacement action before applying. Never delete remote state to roll back.

## Incident triage

1. Check the relevant GitHub Actions workflow.
2. Call `/api/overview` directly to isolate front-end versus API failure.
3. Query Application Insights failures and exceptions.
4. Check Function health and app settings.
5. Confirm managed-identity Reader assignments on both project groups.
6. Run `terraform plan` to identify drift.
