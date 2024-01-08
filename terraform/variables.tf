# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the resources should be deployed into"
}

variable "region" {
  type        = string
  description = "AWS region to be used"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs the VPC endpoints should be deployed into (these are usually not accessible from outside the VPC)"
}

variable "alb_subnet_ids" {
  type        = list(string)
  default     = []
  description = "List of subnet IDs the ALB should be deployed into (these are usually accessible from outside the VPC)"
}

variable "s3_access_allowed_roles" {
  type        = list(string)
  default     = []
  description = "List of role ARNs that should be allowed access to the S3 bucket outside of the VPC endpoint"
}

variable "s3_access_allow_aws_services" {
  type        = bool
  default     = false
  description = "Whether or not requests to the S3 bucket made on behalf of any AWS service should be allowed access to the S3 bucket outside of the VPC endpoint"
}

variable "s3_access_allowed_service_principals" {
  type        = list(string)
  default     = []
  description = "List of service principals that should be allowed access to the S3 bucket outside of the VPC endpoint"
}

variable "domain_name" {
  type        = string
  default     = null
  description = "Domain name for the ALB. If set, will set up an ALB, configure TLS certificate for the ALB (stored in ACM), and set up Route 53 alias, if the hosted_zone_id is set as well."
}

variable "deploy_api" {
  type        = bool
  default     = true
  description = "Deploys an API GW with a Lambda route that generates a pre-signed URL for an object in the bucket. Will be integrated in the ALB in /api/* routes."
}

variable "hosted_zone_id" {
  type        = string
  default     = null
  description = "If hosted_zone_id is set and domain_name is set, will configure a Route 53 DNS entry for the ALB"
}
