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

locals {
  create_code_storage_bucket = var.code_storage_bucket == null
  code_storage_bucket        = local.create_code_storage_bucket ? aws_s3_bucket.code_storage[0].bucket : var.code_storage_bucket
}

resource "aws_s3_bucket" "code_storage" {
  count  = local.create_code_storage_bucket ? 1 : 0
  bucket = "${var.eks_cluster_name}-code-storage-${local.short_uuid}"
}

resource "aws_s3_directory_bucket" "code_storage_express" {
  count  = var.s3_express_zone == null ? 0 : 1
  bucket = "${var.eks_cluster_name}-code-storage-${local.short_uuid}--${var.s3_express_zone}--x-s3"

  location {
    name = var.s3_express_zone
  }
}

resource "aws_s3_bucket_ownership_controls" "code_storage" {
  count  = local.create_code_storage_bucket ? 1 : 0
  bucket = aws_s3_bucket.code_storage[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "code_storage" {
  count  = local.create_code_storage_bucket ? 1 : 0
  bucket = aws_s3_bucket.code_storage[0].id

  versioning_configuration {
    status = "Disabled"
  }
}

# Skip trying to fetch the bucket data directly, as it leads to dependency issues
# in multi-region setups. Instead, just use the bucket name as a string.
