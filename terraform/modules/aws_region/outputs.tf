// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

output "nlb_cert_arn" {
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}

output "iam_serviceaccount_role_arn" {
  value = aws_iam_role.eks_service_account.arn
}

output "code_storage_bucket" {
  value = aws_s3_bucket.code_storage.bucket
}

output "cache_storage_bucket" {
  value = aws_s3_bucket.lsc_storage.bucket
}

output "access_key_id" {
  value = aws_iam_access_key.s3_user_key.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.s3_user_key.secret
  sensitive = true
}
