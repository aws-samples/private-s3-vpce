# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/dependencies/lambda_get_url"
  output_path = "${path.module}/dependencies/lambda_get_url/handler.zip"
  excludes    = ["handler.zip"]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "get_url_role" {
  name               = "GetS3VpceUrlRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.get_url_role.id
}

resource "aws_iam_role_policy_attachment" "lambda_eni_management_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
  role       = aws_iam_role.get_url_role.id
}

data "aws_iam_policy_document" "allow_s3_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_policy" {
  name   = "GetS3VpceUrlRoleS3Policy"
  role   = aws_iam_role.get_url_role.id
  policy = data.aws_iam_policy_document.allow_s3_access.json
}

data "aws_iam_policy_document" "allow_kms_decrypt" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [var.s3_kms_key_arn]
  }
}

resource "aws_iam_role_policy" "kms_policy" {
  name   = "GetS3VpceUrlRoleKmsDecryptPolicy"
  role   = aws_iam_role.get_url_role.id
  policy = data.aws_iam_policy_document.allow_kms_decrypt.json
}

resource "aws_security_group" "lambda_sg" {
  name        = "GetS3VpceLambdaSecurityGroup"
  description = "Allow TLS outbound traffic"
  vpc_id      = var.vpc_id

  egress {
    description = "TLS to VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
}

resource "aws_lambda_function" "get_url" {
  function_name    = "GetS3VpceUrlLambdaFunction"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.11"
  handler          = "app.lambda_handler"
  role             = aws_iam_role.get_url_role.arn
  memory_size      = 128
  timeout          = 15

  # use pre-built layer for Powertools for AWS Lambda (Python): https://docs.powertools.aws.dev/lambda/python/latest/
  layers = ["arn:aws:lambda:${data.aws_region.current.name}:017000801446:layer:AWSLambdaPowertoolsPythonV2:46"]

  environment {
    variables = {
      S3_BUCKET_NAME : var.s3_bucket_name,
      S3_ENDPOINT_URL : "https://${var.s3_endpoint_url}"
    }
  }

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_url.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
