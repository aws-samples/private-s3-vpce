# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the ALB should be deployed into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs the ALB should be deployed into"
}

variable "target_security_group_ids" {
  type        = list(string)
  description = "IDs of security groups which the ALB should be allowed to access on port 443"
}

variable "s3_vpce_id" {
  type        = string
  description = "ID of the S3 VPC endpoint"
}

variable "s3_vpce_nr_ips" {
  type        = number
  description = "Number of IPs (= subnets) for the S3 VPC endpoint"
}

variable "execute_api_vpce_id" {
  type        = string
  description = "ID of the execute-api VPC endpoint"
}

variable "execute_api_vpce_nr_ips" {
  type        = number
  description = "Number of IPs (= subnets) for the execute-api VPC endpoint"
}

variable "attach_api" {
  type        = bool
  description = "Whether to create an API forward rule under /api/* or not"
}

variable "domain_name" {
  type        = string
  description = "Domain name that should be associated with the ALB"
}

variable "hosted_zone_id" {
  type        = string
  default     = null
  description = "If set and domain_name is set, will configure a Route 53 DNS entry for the ALB"
}
