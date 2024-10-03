// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_s3_bucket" "lsc_storage" {
  bucket = "${var.eks_cluster_name}-lsc-storage-${local.short_uuid}"
}

resource "aws_s3_bucket_ownership_controls" "lsc_storage" {
  bucket = aws_s3_bucket.lsc_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "lsc_storage" {
  bucket = aws_s3_bucket.lsc_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket" "code_storage" {
  bucket = "${var.eks_cluster_name}-code-storage-${local.short_uuid}"
}

resource "aws_s3_bucket_ownership_controls" "code_storage" {
  bucket = aws_s3_bucket.code_storage.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "code_storage" {
  bucket = aws_s3_bucket.code_storage.id

  versioning_configuration {
    status = "Disabled"
  }
}
