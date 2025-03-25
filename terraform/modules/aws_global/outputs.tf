// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

output "ga_dns_name" {
  value       = aws_globalaccelerator_accelerator.ga.dns_name
  description = "DNS name of the Global Accelerator"
}

output "ga_hosted_zone_id" {
  value       = aws_globalaccelerator_accelerator.ga.hosted_zone_id
  description = "Hosted zone ID of the Global Accelerator"
}
