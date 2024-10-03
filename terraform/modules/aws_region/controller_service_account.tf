// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_iam_policy" "eks_service_account_policy" {
  name = "eks-service-account-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # TODO: narrow down the permissions
        Effect   = "Allow",
        Action   = "eks:*",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "eks_service_account" {
  name        = "eks-service-account-${local.short_uuid}"
  description = data.aws_eks_cluster_auth.this.id
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.this.account_id}:oidc-provider/${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}"
        }
        Condition = {
          StringEquals = {
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub" : "system:serviceaccount:default:controller"
            "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud" : "sts.amazonaws.com"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_service_account" {
  role       = aws_iam_role.eks_service_account.name
  policy_arn = aws_iam_policy.eks_service_account_policy.arn
}
