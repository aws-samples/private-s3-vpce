# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

variable "service" {
  type        = string
  description = "Service name for the VPC endpoint"
}

variable "endpoint_type" {
  type        = string
  default     = "Interface"
  description = "Type of the VPC endpoint, must be  one of 'Interface', 'Gateway'"

  validation {
    condition     = contains(["Interface", "Gateway"], var.endpoint_type)
    error_message = "endpoint_type must be one of 'Interface', 'Gateway'"
  }
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC the VPC endpoint should be deployed into"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs the VPC endpoint should be deployed into"
}

variable "security_group_ids" {
  type        = list(string)
  description = "List of securitz group IDs that should be associated with the VPC endpoint"
}
