// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

region                  = "aa-example-1"
domain_name             = "private-s3-vpce.example.com"
vpc_id                  = "vpc-01234567890123451"
alb_subnet_ids          = ["subnet-01234567890123451", "subnet-01234567890123452"]
private_subnet_ids      = ["subnet-01234567890123453"]
s3_access_allowed_roles = ["arn:aws:iam::111122223333:role/admin"]
hosted_zone_id          = "Z01234567890123456789"
