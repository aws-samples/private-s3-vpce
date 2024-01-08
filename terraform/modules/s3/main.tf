# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

resource "aws_kms_key" "s3_kms_key" {
  #checkov:skip=CKV2_AWS_64: Use default key policy
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "s3_kms_key" {
  name          = "alias/S3KmsKey"
  target_key_id = aws_kms_key.s3_kms_key.key_id
}

resource "aws_s3_bucket" "private_bucket" {
  #checkov:skip=CKV_AWS_144: No cross-region replication needed in example
  #checkov:skip=CKV2_AWS_62: No event notifications needed in example
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "private_bucket" {
  bucket = aws_s3_bucket.private_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private_bucket" {
  depends_on = [aws_s3_bucket_versioning.private_bucket]
  bucket     = aws_s3_bucket.private_bucket.id

  # expire noncurrent versions
  rule {
    id = "Expiration"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    status = "Enabled"
  }

  # abort incomplete multipart uploads
  rule {
    id = "AbortIncompleteMultipartUploads"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    status = "Enabled"
  }
}


resource "aws_s3_bucket_logging" "logging" {
  bucket        = aws_s3_bucket.private_bucket.id
  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "limit_access" {
  bucket = aws_s3_bucket.private_bucket.id
  policy = data.aws_iam_policy_document.limit_access.json
}

data "aws_iam_policy_document" "limit_access" {
  statement {
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.private_bucket.arn,
      "${aws_s3_bucket.private_bucket.arn}/*",
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [var.s3_vpce_id]
    }

    dynamic "condition" {
      for_each = length(var.s3_access_allowed_roles) > 0 ? [1] : []
      content {
        test     = "ForAllValues:ArnNotEquals"
        variable = "aws:PrincipalARN"
        values   = var.s3_access_allowed_roles
      }
    }

    dynamic "condition" {
      for_each = var.s3_access_allow_aws_services ? [1] : []
      content {
        test     = "BoolIfExists"
        variable = "aws:PrincipalIsAWSService"
        values   = "true"
      }
    }

    dynamic "condition" {
      for_each = length(var.s3_access_allowed_service_principals) > 0 ? [1] : []
      content {
        test     = "ForAllValues:ArnNotEquals"
        variable = "aws:PrincipalServiceName"
        values   = var.s3_access_allowed_service_principals
      }
    }

  }
}


# LOGGING BUCKET
resource "aws_s3_bucket" "logging_bucket" {
  #checkov:skip=CKV_AWS_21: No versioning needed for logging bucket
  #checkov:skip=CKV_AWS_144: No cross-region replication needed in example
  #checkov:skip=CKV2_AWS_62: No event notifications needed in example
  bucket = "${var.bucket_name}-logs"
}

resource "aws_s3_bucket_public_access_block" "logging_bucket" {
  bucket = aws_s3_bucket.logging_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging_bucket" {
  bucket = aws_s3_bucket.logging_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logging_bucket" {
  bucket = aws_s3_bucket.logging_bucket.id

  # expire logs
  rule {
    id = "Expiration"

    expiration {
      days = 30
    }

    status = "Enabled"
  }

  # abort incomplete multipart uploads
  rule {
    id = "AbortIncompleteMultipartUploads"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    status = "Enabled"
  }
}
