// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.


locals {
  certificate_sans = [
    var.cluster_domain_name,
    "*.${var.cluster_domain_name}",
  ]
}

resource "aws_acm_certificate" "cert" {
  count                     = var.enable_loadbalancer_tls_termination ? 1 : 0
  domain_name               = var.cluster_domain_name
  subject_alternative_names = local.certificate_sans
  validation_method         = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

# Certificate validation records
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_loadbalancer_tls_termination ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.zone.id
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  count                   = var.enable_loadbalancer_tls_termination && var.wait_for_acm_validation ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [
    aws_route53_record.cert_validation
  ]
}




