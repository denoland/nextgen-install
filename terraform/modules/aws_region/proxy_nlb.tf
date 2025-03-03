// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

locals {
  service_ssl_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"               = var.enable_loadbalancer_tls_termination ? aws_acm_certificate.cert.0.arn : ""
    "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  }
  service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"  = "ip"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"           = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-type"             = "external"
    "service.beta.kubernetes.io/aws-load-balancer-ip-address-type"  = "dualstack"
    "service.beta.kubernetes.io/aws-load-balancer-subnets"          = aws_subnet.shh_subnet1.id
    "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"        = "443"
    "service.beta.kubernetes.io/aws-load-balancer-name"             = "${module.eks.cluster_name}-nlb"
    "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
    "service.beta.kubernetes.io/aws-load-balancer-alpn-policy"      = "HTTP2Preferred"
  }
}

resource "kubernetes_service" "nlb_proxy_service" {
  depends_on = [module.eks.eks_managed_node_groups]
  metadata {
    name      = "nlb-proxy"
    namespace = var.k8s_namespace
    annotations = merge(
      # If TLS is terminated at the NLB, we need to add the TLS certificate.
      var.enable_loadbalancer_tls_termination ? local.service_ssl_annotations : {},
      local.service_annotations
    )
  }

  spec {
    port {
      name        = "https"
      port        = 443
      protocol    = "TCP"
      target_port = var.enable_loadbalancer_tls_termination ? 8080 : 8443
    }

    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = 8081
    }

    selector = {
      app = "proxy"
    }

    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}
