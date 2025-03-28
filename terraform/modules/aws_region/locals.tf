// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

data "aws_availability_zones" "available" {}
resource "random_uuid" "this" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  # 2 AZs are required for EKS control plane. We only use the 1st AZ.
  eks_cluster_az1 = var.override_az1 != null ? var.override_az1 : element(local.azs, 0)
  eks_cluster_az2 = var.override_az2 != null ? var.override_az2 : element(local.azs, 1)
  short_uuid      = substr(random_uuid.this.result, 0, 8)
}
