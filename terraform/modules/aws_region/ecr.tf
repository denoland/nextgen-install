// Copyright Deno Land Inc. All Rights Reserved. Proprietary and confidential.

resource "aws_ecr_repository" "controller" {
  name = "deno-controller"
}

resource "aws_ecr_repository" "dnsmasq" {
  name = "deno-dnsmasq"
}

resource "aws_ecr_repository" "isolate_worker" {
  name = "deno-isolate-worker"
}

resource "aws_ecr_repository" "lscached" {
  name = "deno-lscached"
}

resource "aws_ecr_repository" "proxy" {
  name = "deno-proxy"
}

resource "aws_ecr_repository" "fake_origin" {
  name = "deno-fake-origin"
}

resource "aws_ecr_repository" "netlify_origin_service" {
  name = "deno-netlify-origin-service"
}
