// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

// This file configures Network Load Balancers for the Global Accelerator path:
// Traffic path: internet -> global accelerator -> nlb_ga_outer -> nlb_ga_inner -> proxy
//   - nlb_ga_outer:
//     - TLS termination: OFF
//     - Proxy protocol: configurable via var.use_proxy_protocol
//     - IPv4 only
//   - nlb_ga_inner:
//     - TLS termination: OFF
//     - Proxy protocol: OFF
//     - Dualstack IPv4/IPv6
//
// Traffic routing:
//   - HTTP traffic (port 80) → always sent to proxy port 8081
//   - HTTPS traffic (port 443):
//     - Since TLS is never terminated → encrypted traffic always sent to proxy port 8443
//
// Note: Traffic passes through both load balancers:
//   1. nlb_ga_outer receives traffic from the global accelerator
//   2. nlb_ga_inner receives traffic from nlb_ga_outer
//   3. proxy receives traffic from nlb_ga_inner

resource "aws_security_group" "sg_nlb_ga_outer" {
  count       = var.enable_global_accelerator ? 1 : 0
  name        = "${var.eks_cluster_name}-nlb-ga-outer-sg"
  description = "Security group for the GA outer Network Load Balancer"
  vpc_id      = aws_vpc.shh_vpc.id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.eks_cluster_name}-nlb-ga-outer-sg"
  }
}

locals {
  # GA inner NLB IP address and annotations
  ip_nlb_ga_inner = cidrhost(aws_subnet.shh_subnet1.cidr_block, 10)
  annotations_nlb_ga_inner = {
    "service.beta.kubernetes.io/aws-load-balancer-scheme"                 = "internal"
    "service.beta.kubernetes.io/aws-load-balancer-private-ipv4-addresses" = local.ip_nlb_ga_inner
    "service.beta.kubernetes.io/aws-load-balancer-name"                   = "${var.eks_cluster_name}-nlb-ga-inner"
  }
}

# Kubernetes service for GA inner NLB
# GA inner NLB: proxy protocol is OFF, TLS termination is OFF
resource "kubernetes_service" "svc_nlb_ga_inner" {
  count      = var.enable_global_accelerator ? 1 : 0
  depends_on = [module.eks.eks_managed_node_groups]
  metadata {
    name      = "${var.eks_cluster_name}-nlb-ga-inner"
    namespace = var.k8s_namespace
    annotations = merge(
      local.service_base_annotations,
      local.annotations_nlb_ga_inner
      # No TLS termination, no proxy protocol for GA inner NLB
    )
  }

  spec {
    port {
      name     = "https"
      port     = 443
      protocol = "TCP"
      # GA inner NLB never terminates TLS, so always send encrypted traffic to 8443
      target_port = 8443
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

# AWS NLB for Global Accelerator (outer facing)
# GA outer NLB: proxy protocol is configurable, TLS termination is OFF
resource "aws_lb" "nlb_ga_outer" {
  count              = var.enable_global_accelerator ? 1 : 0
  name               = "${var.eks_cluster_name}-nlb-ga-outer"
  internal           = false
  load_balancer_type = "network"
  ip_address_type    = "ipv4"
  subnets            = [aws_subnet.shh_subnet1.id]
  security_groups    = [aws_security_group.sg_nlb_ga_outer[0].id]

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.eks_cluster_name}-nlb-ga-outer"
  }
}

# Target groups for GA outer NLB
resource "aws_lb_target_group" "tg_nlb_ga_outer_https" {
  count             = var.enable_global_accelerator ? 1 : 0
  name              = "${substr(var.eks_cluster_name, 0, 20)}-ga-tg-https"
  port              = 443
  protocol          = "TCP"
  vpc_id            = aws_vpc.shh_vpc.id
  target_type       = "ip"
  proxy_protocol_v2 = var.use_proxy_protocol

  health_check {
    enabled             = true
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
  }
}

resource "aws_lb_target_group" "tg_nlb_ga_outer_http" {
  count             = var.enable_global_accelerator ? 1 : 0
  name              = "${substr(var.eks_cluster_name, 0, 20)}-ga-tg-http"
  port              = 80
  protocol          = "TCP"
  vpc_id            = aws_vpc.shh_vpc.id
  target_type       = "ip"
  proxy_protocol_v2 = var.use_proxy_protocol

  health_check {
    enabled             = true
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
  }
}

# Target group attachments connecting GA outer NLB to GA inner NLB
resource "aws_lb_target_group_attachment" "attach_nlb_ga_inner_https" {
  count            = var.enable_global_accelerator ? 1 : 0
  target_group_arn = aws_lb_target_group.tg_nlb_ga_outer_https[0].arn
  target_id        = local.ip_nlb_ga_inner
  port             = 443
}

resource "aws_lb_target_group_attachment" "attach_nlb_ga_inner_http" {
  count            = var.enable_global_accelerator ? 1 : 0
  target_group_arn = aws_lb_target_group.tg_nlb_ga_outer_http[0].arn
  target_id        = local.ip_nlb_ga_inner
  port             = 80
}

# Listeners for GA outer NLB
resource "aws_lb_listener" "listener_nlb_ga_outer_https" {
  count             = var.enable_global_accelerator ? 1 : 0
  load_balancer_arn = aws_lb.nlb_ga_outer[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_nlb_ga_outer_https[0].arn
  }
}

resource "aws_lb_listener" "listener_nlb_ga_outer_http" {
  count             = var.enable_global_accelerator ? 1 : 0
  load_balancer_arn = aws_lb.nlb_ga_outer[0].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_nlb_ga_outer_http[0].arn
  }
}
