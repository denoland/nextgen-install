// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

output "dns_zone_ns_records" {
  value = azurerm_dns_zone.deno_cluster.name_servers
}

output "resource_group_name" {
  value = azurerm_resource_group.deno_cluster.name
}

output "resource_group_location" {
  value = azurerm_resource_group.deno_cluster.location
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.deno_cluster.name
}

output "aks_cluster_fqdn" {
  value = azurerm_kubernetes_cluster.deno_cluster.fqdn
}

output "aks_cluster_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.deno_cluster.oidc_issuer_url
}

output "cert_manager_federated_identity" {
  value = azurerm_federated_identity_credential.cert_manager.id
}

output "deno_cluster_user_assigned_identity_client_id" {
  value = azurerm_user_assigned_identity.deno_cluster.client_id
}

output "values_yaml" {
  value = templatefile("${path.module}/templates/values.yaml.tftpl", {
    region                 = var.region
    hostname               = "${var.dns_root}.${var.dns_zone}"
    cluster_name           = azurerm_kubernetes_cluster.deno_cluster.name
    subscription_id        = data.azurerm_subscription.current.subscription_id
    resource_group         = azurerm_resource_group.deno_cluster.name
    dns_zone               = var.dns_zone
    user_assigned_identity = azurerm_user_assigned_identity.deno_cluster.client_id
  })
}
