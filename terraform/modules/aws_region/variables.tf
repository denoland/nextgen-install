// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

variable "eks_cluster_name" {
  type = string
}

variable "s3_express_zone" {
  type    = string
  default = null
}

variable "use_express_code_storage" {
  type        = bool
  default     = false
  description = "Whether to use S3 Express buckets for code storage"
}

variable "create_eks_policies" {
  type    = bool
  default = true
}


variable "cluster_domain_name" {
  type        = string
  description = "The hostname for this region's API endpoint"
}

variable "cluster_domain_zone" {
  description = "The DNS zone for the API domain (e.g., region.deno.net). If not provided, a zone will be created with the cluster_domain_name value."
  default     = null
  type        = any
}

variable "eks_cluster_region" {
  type = string
}

variable "enable_global_accelerator" {
  type        = bool
  default     = false
  description = "Whether to enable Global Accelerator. If false, use the Kubernetes-created NLB."
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
    name           = string
    ami_type       = string
    instance_types = list(string)
    spot           = bool
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
  })
  default = {
    name           = "static"
    ami_type       = "AL2023_ARM_64_STANDARD"
    instance_types = ["t4g.medium"]
    spot           = true
    min_size       = 1
    max_size       = 1
    desired_size   = 1
    disk_size      = 60
  }
}

variable "enable_loadbalancer_tls_termination" {
  type        = bool
  default     = true
  description = "Terminate TLS at the AWS Network Load Balancer"
}

variable "wait_for_acm_validation" {
  type    = bool
  default = false
}

variable "use_proxy_protocol" {
  type        = bool
  default     = true
  description = "Use proxy protocol for client IP preservation"
}

variable "code_storage_bucket" {
  type        = string
  default     = null
  description = "Name of an existing S3 bucket to use for code storage. If null, a new bucket will be created."
}

variable "karpenter_enabled" {
  description = "If set to `true` the module will setup karpenter"
  type        = bool
  default     = true
}
variable "override_az1" {
  type    = string
  default = null
}

variable "override_az2" {
  type    = string
  default = null
}

variable "create_oidc_provider" {
  type        = bool
  default     = true
  description = "Whether to create the GitHub Actions OIDC provider. Set to false for secondary regions to avoid conflicts."
}
