# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  vpce_services = compact([
    "s3",
    var.deploy_api ? "execute-api" : null
  ])

  bucket_name = try(var.domain_name, "s3-private-vpce-${data.aws_caller_identity.current.account_id}")

  deploy_alb = var.domain_name != null
}

resource "aws_security_group" "vpce_sg" {
  #checkov:skip=CKV2_AWS_5: False positive, SG is attached to VPCE
  name        = "VpceSecurityGroup"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
}

module "s3_gateway_vpce" {
  source = "./modules/vpce"

  service            = "s3"
  endpoint_type      = "Gateway"
  vpc_id             = var.vpc_id
  subnet_ids         = null # not to be set for gateway VPCEs
  security_group_ids = null # not to be set for gateway VPCEs
}

module "vpce" {
  for_each = toset(local.vpce_services)
  source   = "./modules/vpce"

  service            = each.key
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [aws_security_group.vpce_sg.id]

  depends_on = [
    module.s3_gateway_vpce
  ]
}

module "s3" {
  source = "./modules/s3"

  bucket_name = local.bucket_name
  s3_vpce_id  = module.vpce["s3"].id
  s3_access_allowed_roles = concat(
    var.s3_access_allowed_roles,
    var.deploy_api ? [module.api[0].lambda_role_arn] : []
  )
  s3_access_allow_aws_services         = var.s3_access_allow_aws_services
  s3_access_allowed_service_principals = var.s3_access_allowed_service_principals
}

module "api" {
  count  = var.deploy_api ? 1 : 0
  source = "./modules/api"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  domain_name         = var.domain_name
  s3_bucket_name      = module.s3.bucket_name
  s3_kms_key_arn      = module.s3.kms_key_arn
  s3_endpoint_url     = var.domain_name != null ? var.domain_name : replace(module.vpce["s3"].dns_name, "*", "bucket")
  execute_api_vpce_id = module.vpce["execute-api"].id
}

module "alb" {
  count  = local.deploy_alb ? 1 : 0
  source = "./modules/alb"

  vpc_id                    = var.vpc_id
  subnet_ids                = var.alb_subnet_ids
  target_security_group_ids = [aws_security_group.vpce_sg.id]

  s3_vpce_id              = module.vpce["s3"].id
  s3_vpce_nr_ips          = length(var.private_subnet_ids)
  execute_api_vpce_id     = try(module.vpce["execute-api"].id, null)
  execute_api_vpce_nr_ips = length(var.private_subnet_ids)
  attach_api              = var.deploy_api
  domain_name             = var.domain_name
  hosted_zone_id          = var.hosted_zone_id
}
