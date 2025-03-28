// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.us-east-2, aws.eu-west-1]
    }
  }
}
