// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }

  required_version = ">= 1.7.0"
}
