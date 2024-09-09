
variable "name" {
  description = "Name for the resource group and all resources within it. Must be unique within the subscription."
  type        = string
}

variable "region" {
  type = string
}


variable "dns_zone" {
  description = "name of the DNS zone. example: `deno_cluster.net`"
  type        = string
}

variable "dns_root" {
  description = "subdomain where Deno Cluster will be hosted. example: `github` for `github.deno_cluster.net`"
  type        = string
}
