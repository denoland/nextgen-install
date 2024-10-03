// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_iam_openid_connect_provider" "default" {
  url             = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
  client_id_list  = ["sts.amazonaws.com"]
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_user" "s3_user" {
  name = "s3-access-user-${local.short_uuid}"
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy-${local.short_uuid}"
  path        = "/"
  description = "IAM policy for S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.code_storage.arn,
          "${aws_s3_bucket.code_storage.arn}/*",
          aws_s3_bucket.lsc_storage.arn,
          "${aws_s3_bucket.lsc_storage.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the IAM user
resource "aws_iam_user_policy_attachment" "s3_user_policy_attach" {
  user       = aws_iam_user.s3_user.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
