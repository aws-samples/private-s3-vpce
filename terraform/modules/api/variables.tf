# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the API Gateway and Lambda function should be deployed into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs the API Gateway should be deployed into"
}


variable "execute_api_vpce_id" {
  type        = string
  description = "ID of the execute-api VPC endpoint that should be allowed access to the API Gateway"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "s3_endpoint_url" {
  type        = string
  description = "Endpoint URL to be used for the S3 bucket"
}

variable "s3_kms_key_arn" {
  type        = string
  description = "ARN of the KMS key that is used for encrypting S3 bucket contents"
}

variable "domain_name" {
  type        = string
  description = "Domain name that should be associated with the ALB"
}
