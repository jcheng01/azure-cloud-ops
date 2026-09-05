# Troubleshooting notes

These are real failures encountered while building the project.

## Terraform block pasted into PowerShell

**Symptom:** `Terraform has no command named ...` followed by a long encoded-looking string.

**Cause:** HCL was pasted into the terminal, so PowerShell treated `terraform {` as a CLI command. Put HCL in a `.tf` file and run only Terraform commands in the terminal.

## Too many plan arguments

**Symptom:** `Error: Too many command line arguments`.

**Cause:** PowerShell split `-out` incorrectly. Use:

```powershell
terraform plan "-out=cloudops.tfplan"
```

## Static Web App repository fields require a token

**Symptom:** `repository_url`, `repository_branch`, and `repository_token` must all be specified.

**Cause:** AzureRM treats the GitHub connection as an all-or-nothing set. The imported app was already connected by Azure, but the configuration supplied only non-secret fields.

**Fix:** do not commit a GitHub token. Leave the connection portal-managed:

```hcl
lifecycle {
  ignore_changes = [
    repository_url,
    repository_branch,
    repository_token
  ]
}
```

## Functions project root not found

`func` was run from the repository root. Run `Set-Location .\api` first so Core Tools can find `host.json`.

## Worker runtime is None

Core Tools could not infer the language. Use:

```powershell
func start --javascript
func azure functionapp publish func-azure-cloudops-jcheng01 --javascript
```

## Port 7071 already in use

Another Functions host is running. Stop it with Ctrl+C or use `func start --javascript --port 7072`.

## Empty Function hostname variable

**Symptom:** the URL becomes `https:///api/overview`.

**Cause:** the first Azure CLI query returned no hostname, so PowerShell interpolated an empty variable.

**Fix:** query the generic Azure resource:

```powershell
$functionHost = az resource show `
  --name "func-azure-cloudops-jcheng01" `
  --resource-group "rg-azure-cloudops-prod" `
  --resource-type "Microsoft.Web/sites" `
  --query "properties.defaultHostName" `
  --output tsv
```

## Git pull blocked by a local edit

The same file changed locally and remotely. Inspect `git diff`, then commit the intended change or stash it before pulling. Do not discard work until its contents are understood.

## Duplicate Terraform resources and unclosed block

A second copy of the alert resources was appended and the block was incomplete. Keep one canonical block for each Terraform address, then run `terraform fmt` and `terraform validate`.

## Sensitive Terraform output

Terraform propagates sensitivity from `subscription_id`. This project does not output it. If a sensitive output is truly needed, it must explicitly set `sensitive = true`.

## OIDC login failure

The federated credential subject must exactly match:

```text
repo:jcheng01/azure-cloud-ops:ref:refs/heads/main
```

Issuer: `https://token.actions.githubusercontent.com`  
Audience: `api://AzureADTokenExchange`

## Floating-point test failure

JavaScript represented `0.15` as `0.15000000000000002`. Calculated decimals should be compared within a small tolerance; dashboard-facing milliseconds are rounded.
