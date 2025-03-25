// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

locals {
  # Create a new zone if cluster_domain_zone is not provided
  create_zone = var.cluster_domain_zone == null

  # Use either the provided zone or the newly created zone
  zone = local.create_zone ? aws_route53_zone.api_domain_zone[0] : var.cluster_domain_zone
}

# Create a new Route53 zone if one wasn't provided
resource "aws_route53_zone" "api_domain_zone" {
  count = local.create_zone ? 1 : 0
  name  = var.cluster_domain_name

  tags = {
    Name        = var.cluster_domain_name
    Environment = var.eks_cluster_name
    ManagedBy   = "terraform"
  }
}

# Create DNS record for the API endpoint
resource "aws_route53_record" "api_endpoint" {
  zone_id = local.zone.id
  name    = var.cluster_domain_name
  type    = "A"

  alias {
    name                   = data.aws_lb.nlb_direct.dns_name
    zone_id                = data.aws_lb.nlb_direct.zone_id
    evaluate_target_health = true
  }
}

# Create wildcard DNS record
resource "aws_route53_record" "api_endpoint_wildcard" {
  zone_id = local.zone.id
  name    = "*.${var.cluster_domain_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.nlb_direct.dns_name
    zone_id                = data.aws_lb.nlb_direct.zone_id
    evaluate_target_health = true
  }
}

