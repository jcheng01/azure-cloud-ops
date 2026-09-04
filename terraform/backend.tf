terraform {
  backend "azurerm" {
    resource_group_name  = "rg-cloudops-lab"
    storage_account_name = "stcloudopstfjcheng01"
    container_name       = "tfstate"
    key                  = "azure-cloud-ops.tfstate"

    use_azuread_auth = true
    use_cli          = true
  }
}