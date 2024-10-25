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

variable "eks_node_group" {
  description = "Configuration for the static EKS managed node group"
  type = object({
    ami_type       = string
    instance_types = list(string)
    spot           = bool
    min_size       = number
    max_size       = number
    desired_size   = number
  })
  default = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3a.medium"]
    spot           = true
    min_size       = 1
    max_size       = 1
    desired_size   = 1
  }
}
