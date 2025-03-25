// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

variable "environment_name" {
  type        = string
  description = "The name of the environment (e.g., dev, prod)"
}

variable "apps_domain" {
  description = "The public domain name for the application (e.g., deno.net)"
  default     = null
}

variable "cluster_domain_zone" {
  description = "The DNS zone for the cluster domain (e.g., region.deno.net)"
}

variable "global_accelerator_ip" {
  description = "Global Accelerator IP address (null for AWS-allocated)"
  type        = string
  default     = null

  validation {
    condition     = var.global_accelerator_ip == null || can(regex("^(\\d{1,3}\\.){3}\\d{1,3}$", var.global_accelerator_ip))
    error_message = "Must be a valid IPv4 address or null"
  }
}

variable "region_configs" {
  type = list(object({
    region                          = string
    nlb_global_accelerator_arn      = string
    nlb_global_accelerator_dns_name = string
    nlb_global_accelerator_zone_id  = string
    weight                          = optional(number, 100)
  }))
  description = "Configuration for each region with NLB details"
}

