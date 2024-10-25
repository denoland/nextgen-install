// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

output "nlb_cert_arn" {
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}

output "iam_serviceaccount_role_arn" {
  value = aws_iam_role.eks_service_account.arn
}

output "iam_s3_serviceaccount_role_arn" {
  value = aws_iam_role.eks_lscached_service_account.arn
}

output "code_storage_bucket" {
  value = aws_s3_bucket.code_storage.bucket
}

output "cache_storage_bucket" {
  value = aws_s3_bucket.lsc_storage.bucket
}

output "values_yaml" {
  value = templatefile("${path.module}/templates/values.yaml.tftpl", {
    region                = var.eks_cluster_region
    hostname              = var.domain_name
    cluster_name          = var.eks_cluster_name
    subnet                = aws_subnet.shh_subnet1.tags["Name"]
    nlb                   = data.aws_lb.nlb.name
    code_bucket           = aws_s3_bucket.code_storage.id
    cache_bucket          = aws_s3_bucket.lsc_storage.id
    basic_service_account = aws_iam_role.eks_service_account.arn
    cache_service_account = aws_iam_role.eks_lscached_service_account.arn
  })
}
