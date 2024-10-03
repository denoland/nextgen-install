// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

variable "eks_cluster_name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "eks_cluster_region" {
  type = string
}

variable "k8s_namespace" {
  type    = string
  default = "default"
}

variable "enable_cluster_creator_admin_permissions" {
  type    = bool
  default = false
}
