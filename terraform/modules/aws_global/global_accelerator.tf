// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_globalaccelerator_accelerator" "ga" {
  name            = "${var.environment_name}-ga"
  ip_addresses    = var.global_accelerator_ip != null ? [var.global_accelerator_ip] : null
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "ga_listener_http" {
  accelerator_arn = aws_globalaccelerator_accelerator.ga.id
  protocol        = "TCP"
  client_affinity = "SOURCE_IP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_listener" "ga_listener_https" {
  accelerator_arn = aws_globalaccelerator_accelerator.ga.id
  protocol        = "TCP"
  client_affinity = "SOURCE_IP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

# HTTP Endpoint Groups - one per region
resource "aws_globalaccelerator_endpoint_group" "ga_endpoint_group_http" {
  for_each = { for idx, config in var.region_configs : config.region => config }

  listener_arn          = aws_globalaccelerator_listener.ga_listener_http.id
  endpoint_group_region = each.value.region

  endpoint_configuration {
    endpoint_id                    = each.value.nlb_global_accelerator_arn
    weight                         = each.value.weight
    client_ip_preservation_enabled = true
  }

  health_check_port             = 80
  health_check_protocol         = "HTTP"
  health_check_path             = "/"
  health_check_interval_seconds = 30
  threshold_count               = 3
}

# HTTPS Endpoint Groups - one per region
resource "aws_globalaccelerator_endpoint_group" "ga_endpoint_group_https" {
  for_each = { for idx, config in var.region_configs : config.region => config }

  listener_arn          = aws_globalaccelerator_listener.ga_listener_https.id
  endpoint_group_region = each.value.region

  endpoint_configuration {
    endpoint_id                    = each.value.nlb_global_accelerator_arn
    weight                         = each.value.weight
    client_ip_preservation_enabled = true
  }

  health_check_port             = 443
  health_check_protocol         = "HTTPS"
  health_check_path             = "/"
  health_check_interval_seconds = 30
  threshold_count               = 3
}
