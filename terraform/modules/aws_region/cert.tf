// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

moved {
  from = aws_acm_certificate.cert
  to   = aws_acm_certificate.cert[0]
}

resource "aws_acm_certificate" "cert" {
  count       = var.enable_loadbalancer_tls_termination ? 1 : 0
  domain_name = var.domain_name
  subject_alternative_names = [
    "*.${var.domain_name}",
  ]
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

moved {
  from = aws_acm_certificate_validation.cert_validation
  to   = aws_acm_certificate_validation.cert_validation[0]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  count                   = var.wait_for_acm_validation ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert.0.arn
  validation_record_fqdns = [for record in aws_route53_record.record_set1 : record.fqdn]
}
