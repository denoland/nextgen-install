// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

data "aws_caller_identity" "current" {}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are 'ipv4' (default) and 'ipv6'"
  type        = string
  default     = "ipv4"
}

variable "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "cluster_region" {
  description = "The name of the EKS cluster region"
  type        = string
}

variable "controller_pod_annotations" {
  description = "Karpenter controllers podAnnotations"
  type        = map(string)
  default     = {}
}

variable "controller_resources_requests_cpu" {
  description = "Karpenter controllers deployment resources.requests.cpu"
  type        = string
  default     = "1"
}

variable "controller_resources_requests_memory" {
  description = "Karpenter controllers deployment resources.requests.memory"
  type        = string
  default     = "1Gi"
}

variable "controller_resources_limits_memory" {
  description = "Karpenter controllers deployment resources.limits.memory"
  type        = string
  default     = "1Gi"
}

variable "create_pod_identity_association" {
  description = "Determines whether to create pod identity association"
  type        = bool
  default     = true
}

variable "karpenter_version" {
  description = "The karpenter version to install"
  type        = string
  default     = "1.3.0"
}

variable "install_karpenter_crds" {
  description = "If set to 'true' the karpenter crds will be installed"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Namespace to associate with the Karpenter Pod Identity"
  type        = string
  default     = "kube-system"
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = ""
}
variable "spotToSpotConsolidationEnabled" {
  description = "If set to `true' the SpotToSpotConsolidation FeatureGate will be enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(any)
  default     = {}
}
