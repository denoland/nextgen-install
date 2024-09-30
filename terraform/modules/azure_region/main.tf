data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "deno_cluster" {
  location = var.region
  name     = var.name
}

resource "azurerm_kubernetes_cluster" "deno_cluster" {
  name                = "${azurerm_resource_group.deno_cluster.name}-k8s"
  resource_group_name = azurerm_resource_group.deno_cluster.name
  location            = azurerm_resource_group.deno_cluster.location
  dns_prefix          = "${azurerm_resource_group.deno_cluster.name}-k8s"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
  }

  default_node_pool {
    name         = "agentpool"
    os_disk_type = "Ephemeral"
    vm_size      = "Standard_D4ds_v4"

    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 10

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.deno_cluster.id
    ]
  }
}

resource "random_string" "storage_account_suffix" {
  length = 5

  lower   = false
  numeric = true
  special = false
  upper   = false

  keepers = {
    resource_group = azurerm_resource_group.deno_cluster.name
  }
}

resource "azurerm_storage_account" "deno_cluster" {
  name                = "${replace(azurerm_resource_group.deno_cluster.name, "/[^\\w]/", "")}${random_string.storage_account_suffix.id}"
  resource_group_name = azurerm_resource_group.deno_cluster.name
  location            = azurerm_resource_group.deno_cluster.location

  # account_kind                    = "StorageV2" < we're using this
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  identity {
    type = "UserAssigned"
    identity_ids = [
      data.azurerm_user_assigned_identity.deno_cluster.id
    ]
  }
}

resource "azurerm_storage_container" "deployments_storage_container" {
  name                  = "deployments"
  storage_account_name  = azurerm_storage_account.deno_cluster.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "cache_storage_container" {
  name                  = "cache"
  storage_account_name  = azurerm_storage_account.deno_cluster.name
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "deno_cluster" {
  name                = "${azurerm_resource_group.deno_cluster.name}-identity"
  location            = azurerm_resource_group.deno_cluster.location
  resource_group_name = azurerm_resource_group.deno_cluster.name
}

resource "azurerm_federated_identity_credential" "cert_manager" {
  name                = "cert-manager"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.deno_cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.deno_cluster.id
  resource_group_name = azurerm_resource_group.deno_cluster.name
  subject             = "system:serviceaccount:cert-manager:cert-manager"
}

resource "azurerm_role_assignment" "cert_manager_dns_contributor" {
  role_definition_name = "DNS Zone Contributor"
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.deno_cluster.principal_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  role_definition_name = "Storage Blob Data Contributor"
  scope                = data.azurerm_subscription.current.id
  principal_id         = azurerm_user_assigned_identity.deno_cluster.principal_id
}

resource "azurerm_dns_zone" "deno_cluster" {
  name                = var.dns_zone
  resource_group_name = azurerm_resource_group.deno_cluster.name
}

resource "azurerm_dns_cname_record" "apex_record" {
  name                = var.dns_root
  resource_group_name = azurerm_resource_group.deno_cluster.name
  zone_name           = var.dns_zone

  record = "deno-cluster-proxy.${var.region}.cloudapp.azure.com."
  ttl    = 3600

  depends_on = [azurerm_dns_zone.deno_cluster]
}

resource "azurerm_dns_cname_record" "wildcard_record" {
  name                = "*.${var.dns_root}"
  resource_group_name = azurerm_resource_group.deno_cluster.name
  zone_name           = azurerm_dns_zone.deno_cluster.name

  target_resource_id = azurerm_dns_cname_record.apex_record.id
  ttl                = 3600

  depends_on = [azurerm_dns_zone.deno_cluster]
}
