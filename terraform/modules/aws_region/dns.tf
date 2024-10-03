// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_route53_zone" "domain_name" {
  name = "${var.domain_name}."
}

resource "aws_route53_record" "record_set1" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  ttl             = 60
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id         = aws_route53_zone.domain_name.zone_id
}

data "aws_lb" "nlb" {
  depends_on = [kubernetes_service.nlb_proxy_service]
  name       = "${var.eks_cluster_name}-nlb"
}

resource "aws_route53_record" "apex_a_record" {
  name = "${var.domain_name}."
  type = "A"

  alias {
    name                   = data.aws_lb.nlb.dns_name
    zone_id                = data.aws_lb.nlb.zone_id
    evaluate_target_health = true
  }

  zone_id = aws_route53_zone.domain_name.zone_id
}

resource "aws_route53_record" "wildcard_a_record" {
  name = "*.${var.domain_name}."
  type = "A"

  alias {
    name                   = data.aws_lb.nlb.dns_name
    zone_id                = data.aws_lb.nlb.zone_id
    evaluate_target_health = false
  }

  zone_id = aws_route53_zone.domain_name.zone_id
}
