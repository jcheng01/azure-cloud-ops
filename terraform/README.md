# Terraform — Phase 5 Network Architecture

This configuration uses the existing `rg-cloudops-lab` resource group and creates:

| Resource | Address space |
|---|---|
| `vnet-cloudops` | `10.20.0.0/16` |
| `snet-web` | `10.20.1.0/24` |
| `snet-app` | `10.20.2.0/24` |
| `snet-data` | `10.20.3.0/24` |

Each subnet is associated with a dedicated network security group:

| Subnet | Network security group |
|---|---|
| `snet-web` | `nsg-web` |
| `snet-app` | `nsg-app` |
| `snet-data` | `nsg-data` |

The NSGs currently contain only Azure's default security rules. Custom tier-to-tier rules will be added after the required application traffic is defined.

The resource group's location is discovered with an AzureRM data source, so it is not duplicated in configuration. This phase does not create or modify the resource group.

## Prerequisites

- Terraform installed
- Azure CLI installed
- Access to the Azure subscription containing `rg-cloudops-lab`
- Permission to create networking resources in that resource group

## Deploy from PowerShell

```powershell
az login
az account set --subscription "<subscription-id>"
az account show --output table

cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```

Replace the placeholder in `terraform.tfvars`, then run:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

Review the plan before applying. A completely new deployment should show ten resources to add: one virtual network, three subnets, three NSGs, and three subnet-to-NSG associations. If the VNet and subnets are already managed by this Terraform state, the plan should instead show six resources to add.

## Verify with Azure CLI

```powershell
az network vnet show `
  --resource-group rg-cloudops-lab `
  --name vnet-cloudops `
  --output table

az network vnet subnet list `
  --resource-group rg-cloudops-lab `
  --vnet-name vnet-cloudops `
  --output table
```

## State and automation

Terraform state is local for this first phase and is excluded from Git. Before GitHub Actions is allowed to apply infrastructure, state will be moved to an Azure Storage backend and GitHub will authenticate to Azure through OpenID Connect rather than a stored client secret.
