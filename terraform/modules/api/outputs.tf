# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

output "lambda_role_arn" {
  value = aws_iam_role.get_url_role.arn
}
