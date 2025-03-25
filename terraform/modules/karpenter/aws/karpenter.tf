// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

# Controller & Node IAM roles, SQS Queue, Eventbridge Rules
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.33"

  cluster_name          = var.cluster_name
  cluster_ip_family     = var.cluster_ip_family
  enable_v1_permissions = true
  namespace             = var.namespace
  queue_name            = var.queue_name == "" ? "karpenter-${var.cluster_region}-${var.cluster_name}" : var.queue_name

  # Name needs to match role name passed to the EC2NodeClass
  node_iam_role_use_name_prefix = false
  node_iam_role_name            = "karpenter-node-${var.cluster_name}"
  # Attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonEKS_CNI_IPv6_Policy          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AmazonEKS_CNI_IPv6_Policy"
    AmazonEKSWorkerNodePolicy          = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    AmazonSSMManagedInstanceCore       = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  create_pod_identity_association = var.create_pod_identity_association

  tags = var.tags
}

# Optionally, install and manage karpenter CRD's
resource "helm_release" "karpenter_crds" {
  count = var.install_karpenter_crds ? 1 : 0

  namespace  = var.namespace
  name       = "karpenter-crd"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter-crd"
  version    = var.karpenter_version

  depends_on = [
    module.karpenter
  ]
}

# karpenter controller
resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = var.namespace
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  values = [
    <<-EOT
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
      featureGates:
        spotToSpotConsolidation: ${var.spotToSpotConsolidationEnabled}
    controller:
      resources:
        requests:
          cpu: ${var.controller_resources_requests_cpu}
          memory: ${var.controller_resources_requests_memory}
        limits:
          memory: ${var.controller_resources_limits_memory}
    tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
    EOT
  ]

  # Additionally provided podAnnotations
  dynamic "set" {
    for_each = var.controller_pod_annotations
    content {
      name  = "podAnnotations.${set.key}"
      value = set.value
      type  = "string"
    }
  }

  depends_on = [
    helm_release.karpenter_crds
  ]
}

