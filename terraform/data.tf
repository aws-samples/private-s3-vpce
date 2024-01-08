# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# Copyright 2023 maritsch.
# SPDX-License-Identifier: MIT-0

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_caller_identity" "current" {
}
