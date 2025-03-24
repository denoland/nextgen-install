// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

// This file configures the direct Network Load Balancer for the proxy service:
// Traffic path: internet -> nlb_direct -> proxy
//   - TLS termination: configurable via var.enable_loadbalancer_tls_termination
//   - Proxy protocol: configurable via var.use_proxy_protocol
//
// Traffic routing:
//   - HTTP traffic (port 80) → always sent to proxy port 8081
//   - HTTPS traffic (port 443):
//     - If TLS termination is enabled → decrypted traffic sent to proxy port 8080
//     - If TLS termination is disabled → encrypted traffic sent to proxy port 8443

# Data source to fetch the Kubernetes-created direct NLB
data "aws_lb" "nlb_direct" {
  name       = "${var.eks_cluster_name}-nlb-direct"
  depends_on = [kubernetes_service.svc_nlb_direct]
}

locals {
  # Common annotations for all NLB services
  service_base_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"  = "ip"
    "service.beta.kubernetes.io/aws-load-balancer-type"             = "external"
    "service.beta.kubernetes.io/aws-load-balancer-ip-address-type"  = "dualstack"
    "service.beta.kubernetes.io/aws-load-balancer-subnets"          = aws_subnet.shh_subnet1.id
    "service.beta.kubernetes.io/aws-load-balancer-ssl-ports"        = "443"
    "service.beta.kubernetes.io/aws-load-balancer-backend-protocol" = "tcp"
    "service.beta.kubernetes.io/aws-load-balancer-alpn-policy"      = "HTTP2Preferred"
  }

  # Direct NLB specific annotations
  service_nlb_direct_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-name"   = "${module.eks.cluster_name}-nlb-direct"
  }

  # SSL termination annotations
  service_ssl_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-ssl-cert"               = var.enable_loadbalancer_tls_termination ? aws_acm_certificate.cert.0.arn : ""
    "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  }

  # Proxy protocol annotations
  service_proxy_protocol_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-proxy-protocol" = "*"
  }
}

# Kubernetes service for direct NLB
# Direct NLB: TLS termination is configurable, proxy protocol is configurable
resource "kubernetes_service" "svc_nlb_direct" {
  depends_on = [module.eks.eks_managed_node_groups]
  metadata {
    name      = "${var.eks_cluster_name}-nlb-direct"
    namespace = var.k8s_namespace
    annotations = merge(
      local.service_base_annotations,
      local.service_nlb_direct_annotations,
      # If TLS is terminated at the NLB, we need to add the TLS certificate
      var.enable_loadbalancer_tls_termination ? local.service_ssl_annotations : {},
      # If proxy protocol is enabled, we need to add the proxy protocol annotation
      var.use_proxy_protocol ? local.service_proxy_protocol_annotations : {}
    )
  }

  spec {
    port {
      name     = "https"
      port     = 443
      protocol = "TCP"
      # If TLS is terminated at the LB, send decrypted HTTPS traffic to 8080
      # Otherwise, send still-encrypted traffic to 8443
      target_port = var.enable_loadbalancer_tls_termination ? 8080 : 8443
    }

    port {
      name     = "http"
      port     = 80
      protocol = "TCP"
      # Plaintext HTTP traffic always goes to 8081
      target_port = 8081
    }

    selector = {
      app = "proxy"
    }

    type                = "LoadBalancer"
    load_balancer_class = "service.k8s.aws/nlb"
  }
}
