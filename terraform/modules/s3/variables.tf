# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "s3_vpce_id" {
  type        = string
  description = "ID of the S3 VPC endpoint that should be allowed access to the S3 bucket"
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
