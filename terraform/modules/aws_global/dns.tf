// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

locals {
  # Check if apps_domain_name is a subdomain of cluster_domain_zone
  apps_domain_suffix              = var.apps_domain != null ? "${var.apps_domain.name}." : ""
  cluster_domain_suffix           = "${var.cluster_domain_zone.name}."
  cluster_domain_needs_delegation = var.apps_domain != null && endswith(local.cluster_domain_suffix, local.apps_domain_suffix)
}

# DNS records for the apps domain
resource "aws_route53_record" "apex_a_record" {
  count = var.apps_domain != null && var.global_accelerator_ip != null ? 1 : 0

  name    = var.apps_domain.name
  type    = "A"
  ttl     = 300
  records = [var.global_accelerator_ip]
  zone_id = var.apps_domain.id
}

# Wildcard DNS records for the apps domain
resource "aws_route53_record" "wildcard_a_record" {
  count = var.apps_domain != null && var.global_accelerator_ip != null ? 1 : 0

  name    = "*.${var.apps_domain.name}"
  type    = "A"
  ttl     = 300
  records = [var.global_accelerator_ip]
  zone_id = var.apps_domain.id
}

# If apps domain is the root of the cluster_domain_zone, create NS record for delegation
resource "aws_route53_record" "private_domain_delegation" {
  count = var.apps_domain != null && local.cluster_domain_needs_delegation ? 1 : 0

  zone_id = var.apps_domain.id
  name    = var.cluster_domain_zone.name
  type    = "NS"
  ttl     = 300
  records = var.cluster_domain_zone.name_servers
}
