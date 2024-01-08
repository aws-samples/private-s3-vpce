# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "bucket_name" {
  value = aws_s3_bucket.private_bucket.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.s3_kms_key.arn
}
