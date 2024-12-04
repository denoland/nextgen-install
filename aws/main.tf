// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  eks_cluster_name                         = "gargamel"
  eks_cluster_region                       = "us-west-2"
  domain_name                              = "gargamel.deno-cluster.net"
  enable_cluster_creator_admin_permissions = true
}

module "aws_region" {
  source = "../terraform/modules/aws_region"

  eks_cluster_name                         = local.eks_cluster_name
  eks_cluster_region                       = local.eks_cluster_region
  domain_name                              = local.domain_name
  enable_cluster_creator_admin_permissions = local.enable_cluster_creator_admin_permissions
}

output "code_storage_bucket" {
  value = module.aws_region.code_storage_bucket
}

output "cache_storage_bucket" {
  value = module.aws_region.cache_storage_bucket
}

output "iam_serviceaccount_role_arn" {
  value = module.aws_region.iam_serviceaccount_role_arn
}

output "iam_lscache_serviceaccount_role_arn" {
  value = module.aws_region.iam_s3_serviceaccount_role_arn
}

output "acm_certificate_arn" {
  value = module.aws_region.nlb_cert_arn
}

output "hosted_zone_nameservers" {
  value = module.aws_region.hosted_zone_nameservers
}

output "values_yaml" {
  value = module.aws_region.values_yaml
}

resource "local_file" "values_yaml" {
    content  = module.aws_region.values_yaml
    filename = "values.yaml"
}
