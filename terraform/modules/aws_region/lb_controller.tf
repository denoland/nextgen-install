// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "helm_release" "lb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.1"

  set {
    name  = "region"
    value = var.eks_cluster_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.shh_vpc.id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.eks_cluster_region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller.arn
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
}
