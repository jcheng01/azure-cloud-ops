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

The custom inbound rules model a segmented three-tier workload:

| NSG | Priority | Action | Source | Destination | TCP port |
|---|---:|---|---|---|---:|
| `nsg-web` | 100 | Allow | `Internet` | `10.20.1.0/24` | 443 |
| `nsg-web` | 4000 | Deny | `VirtualNetwork` | `10.20.1.0/24` | Any |
| `nsg-app` | 100 | Allow | `10.20.1.0/24` | `10.20.2.0/24` | 8080 |
| `nsg-app` | 4000 | Deny | `VirtualNetwork` | `10.20.2.0/24` | Any |
| `nsg-data` | 100 | Allow | `10.20.2.0/24` | `10.20.3.0/24` | 443 |
| `nsg-data` | 4000 | Deny | `VirtualNetwork` | `10.20.3.0/24` | Any |

The priority-4000 rules override Azure's default `AllowVnetInBound` rule while allowing the intended flows first. NSGs are stateful, so response traffic for an allowed connection does not require a matching reverse-direction inbound rule.

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

Review the plan before applying. A completely new deployment should show sixteen resources to add: one virtual network, three subnets, three NSGs, three subnet-to-NSG associations, and six custom rules. If the network and NSG resources are already managed by this Terraform state, the plan should show six rules to add.

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
