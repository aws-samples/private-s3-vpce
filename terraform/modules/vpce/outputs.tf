# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "id" {
  value = aws_vpc_endpoint.endpoint.id
}

output "dns_name" {
  value = try(aws_vpc_endpoint.endpoint.dns_entry[0].dns_name, null)
}
