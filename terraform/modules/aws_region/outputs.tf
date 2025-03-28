// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

output "iam_serviceaccount_role_arn" {
  value = aws_iam_role.eks_service_account.arn
}

output "iam_s3_serviceaccount_role_arn" {
  value = aws_iam_role.eks_lscached_service_account.arn
}

output "code_storage_bucket" {
  value = local.code_storage_bucket
}

output "cache_storage_bucket" {
  value = aws_s3_bucket.lsc_storage.bucket
}

output "cluster_domain_zone_nameservers" {
  value = local.create_zone ? aws_route53_zone.api_domain_zone[0].name_servers : []
}

output "nlb_global_accelerator_arn" {
  value = var.enable_global_accelerator ? aws_lb.nlb_ga_outer[0].arn : try(data.aws_lb.nlb_direct.arn, "")
}

output "nlb_global_accelerator_dns_name" {
  value       = var.enable_global_accelerator ? aws_lb.nlb_ga_outer[0].dns_name : try(data.aws_lb.nlb_direct.dns_name, "")
  description = "DNS name of the Network Load Balancer used for applications"
}

output "nlb_global_accelerator_zone_id" {
  value       = var.enable_global_accelerator ? aws_lb.nlb_ga_outer[0].zone_id : try(data.aws_lb.nlb_direct.zone_id, "")
  description = "Route53 zone ID of the Network Load Balancer used for applications"
}


output "values_yaml" {
  value = templatefile("${path.module}/templates/values.yaml.tftpl", {
    region                      = var.eks_cluster_region
    cluster_domain_name         = var.cluster_domain_name
    cluster_name                = var.eks_cluster_name
    code_storage_bucket         = local.code_storage_bucket
    cache_storage_bucket        = aws_s3_bucket.lsc_storage.id
    basic_service_account       = aws_iam_role.eks_service_account.arn
    cache_service_account       = aws_iam_role.eks_lscached_service_account.arn
    proxy_service_account       = aws_iam_role.eks_proxy_service_account.arn
    use_proxy_protocol          = var.use_proxy_protocol
    s3_express_zone             = var.s3_express_zone
    use_express_code_storage    = var.use_express_code_storage
    express_code_storage_bucket = var.s3_express_zone != null ? aws_s3_directory_bucket.code_storage_express[0].bucket : null
  })
}

output "express_code_storage_bucket" {
  value       = var.s3_express_zone != null ? aws_s3_directory_bucket.code_storage_express[0].bucket : null
  description = "The name of the S3 Express bucket for code storage"
}
