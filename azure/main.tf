provider "azurerm" {
  subscription_id = "522b185c-ec06-4a7d-83bb-21278d70f057" # <- Fill in your Azure subscription ID here.
  environment     = "public"
  features {}
}

locals {
  dns_zone = "deno-cluster.net" # <— The DNS zone that terraform will create in Azure.
  dns_root = "gargamel"         # <— The leftmost label of your cluster domain name.
  name     = "gargamel"         # <— This name will be used to create a new resource group and name various resources.
  region   = "westus"           # <— The Azure region to deploy to.
}

# Leave everything below this line as is.

module "azure_region" {
  source = "../terraform/modules/azure_region"

  name     = local.name
  region   = local.region
  dns_root = local.dns_root
  dns_zone = local.dns_zone
}

output "cluster_domain" {
  value = "${local.dns_root}.${local.dns_zone}"
}

output "dns_zone_ns_records" {
  value = module.azure_region.dns_zone_ns_records
}

output "resource_group_name" {
  value = module.azure_region.resource_group_name
}

output "aks_cluster_name" {
  value = module.azure_region.aks_cluster_name
}

output "deno_cluster_user_assigned_identity_client_id" {
  value = module.azure_region.deno_cluster_user_assigned_identity_client_id
}

output "storage_account_name" {
  value = module.azure_region.storage_account_name
}

output "storage_account_endpoint" {
  value = module.azure_region.storage_account_endpoint
}
