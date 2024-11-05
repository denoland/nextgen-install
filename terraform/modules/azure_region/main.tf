// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

data "azurerm_subscription" "current" {
}

resource "null_resource" "azure_provider_registration" {
  for_each = toset([
    "Microsoft.Network",
    "Microsoft.Storage",
    "Microsoft.Compute",
    "Microsoft.ContainerService",
  ])

  provisioner "local-exec" {
    command = "az provider register --verbose --subscription ${data.azurerm_subscription.current.subscription_id} --namespace ${each.key}"
  }
}

resource "azurerm_resource_group" "deno_cluster" {
  location = var.region
  name     = var.name

  depends_on = [null_resource.azure_provider_registration]
}

resource "azurerm_kubernetes_cluster" "deno_cluster" {
  name                = "${azurerm_resource_group.deno_cluster.name}-k8s"
  resource_group_name = azurerm_resource_group.deno_cluster.name
  location            = var.region
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
    type = "SystemAssigned"
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

resource "azurerm_user_assigned_identity" "deno_cluster" {
  name                = "${azurerm_resource_group.deno_cluster.name}-identity"
  location            = var.region
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
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "DNS Zone Contributor"
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

