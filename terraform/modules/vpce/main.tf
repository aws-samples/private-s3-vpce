# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_vpc_endpoint_service" "endpoint_service" {
  service      = var.service
  service_type = var.endpoint_type
}

resource "aws_vpc_endpoint" "endpoint" {
  private_dns_enabled = var.endpoint_type == "Interface" # only enable DNS for interface endpoints
  service_name        = data.aws_vpc_endpoint_service.endpoint_service.service_name
  vpc_id              = var.vpc_id
  security_group_ids  = var.security_group_ids
  subnet_ids          = var.subnet_ids
  vpc_endpoint_type   = var.endpoint_type
}
