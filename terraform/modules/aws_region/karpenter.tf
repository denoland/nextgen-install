// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

module "karpenter" {
  count  = var.karpenter_enabled ? 1 : 0
  source = "../karpenter/aws"

  cluster_name      = module.eks.cluster_name
  cluster_region    = var.eks_cluster_region
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_ip_family = "ipv6"

  controller_pod_annotations = {
    "prometheus\\.io/path"   = "/metrics"
    "prometheus\\.io/port"   = "8080"
    "prometheus\\.io/scrape" = "true"
  }
}

