variable "subscription_id" {
  description = "Azure subscription ID containing the existing CloudOps resource group."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "resource_group_name" {
  description = "Name of the existing Azure resource group."
  type        = string
  default     = "rg-cloudops-lab"
}

variable "vnet_name" {
  description = "Name of the CloudOps virtual network."
  type        = string
  default     = "vnet-cloudops"
}

variable "vnet_address_space" {
  description = "Address space assigned to the CloudOps virtual network."
  type        = list(string)
  default     = ["10.20.0.0/16"]

  validation {
    condition     = alltrue([for prefix in var.vnet_address_space : can(cidrnetmask(prefix))])
    error_message = "Every VNet address-space value must be valid CIDR notation."
  }
}

variable "subnets" {
  description = "Map of subnet names to CIDR prefixes."
  type        = map(string)
  default = {
    snet-web  = "10.20.1.0/24"
    snet-app  = "10.20.2.0/24"
    snet-data = "10.20.3.0/24"
  }

  validation {
    condition     = alltrue([for prefix in values(var.subnets) : can(cidrnetmask(prefix))])
    error_message = "Every subnet prefix must be valid CIDR notation."
  }
}

variable "tags" {
  description = "Tags applied to resources that support tags."
  type        = map(string)
  default = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
    Project     = "AzureCloudOps"
  }
}

variable "alert_email_address" {
  description = "Email address that receives Azure Monitor and budget alerts."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "monthly_budget_amount" {
  description = "Monthly Azure budget for both CloudOps resource groups, in USD."
  type        = number
  default     = 5

  validation {
    condition     = var.monthly_budget_amount > 0
    error_message = "The monthly budget amount must be greater than zero."
  }
}
