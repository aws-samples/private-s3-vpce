# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import os
import re
from typing import Dict, Any

import botocore.exceptions
import boto3
from botocore.config import Config
from aws_lambda_powertools import Logger, Tracer
from aws_lambda_powertools.event_handler.api_gateway import ApiGatewayResolver
from aws_lambda_powertools.event_handler.exceptions import (
    BadRequestError,
    NotFoundError,
)
from aws_lambda_powertools.utilities.typing import LambdaContext

AWS_LAMBDA_FUNCTION_NAME = os.environ["AWS_LAMBDA_FUNCTION_NAME"]
S3_BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
S3_ENDPOINT_URL = os.environ["S3_ENDPOINT_URL"]
DEFAULT_EXPIRATOIN = 1 * 60 * 60  # 1 hour

tracer = Tracer()
logger = Logger()
app = ApiGatewayResolver()
s3_client = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT_URL,
    verify=False,
    config=Config(s3={"addressing_style": "virtual"}),
)


def strip_bucket_from_path(*, request: Any, **_kw):
    """Strips the bucket name from the path.

    Our requests are proxied through an ALB, and we have the domain name matching the bucket name.
    This can currently not be handled by boto3 and we need to manually alter the URL before signing the request
    from: https://private-s3-vpce.example.com/private-s3-vpce.example.com/test.html
    to: https://private-s3-vpce.example.com/test.html

    Args:
        request (Any): _description_
    """
    request.url = re.sub(f"(https:\/\/[^\/]*)(\/{S3_BUCKET_NAME})", r"\1", request.url)


s3_client.meta.events.register("before-sign.s3.GetObject", strip_bucket_from_path)
s3_client.meta.events.register("before-sign.s3.HeadObject", strip_bucket_from_path)


def create_presigned_url(key: str, expiration: int) -> str:
    """Creates a pre-signed URL for the provided key.

    Args:
        key (str): key of the object on s3
        expiration (str): expiration time in seconds

    Returns:
        str: pre-signed url to download file
    """
    return s3_client.generate_presigned_url(
        "get_object",
        Params={"Bucket": S3_BUCKET_NAME, "Key": key},
        ExpiresIn=expiration,
    )


@app.get("/api/get_url")
def get_url() -> Dict[str, str]:
    """Generates a pre-signed URL to download the given key (file) from S3.

    Raises:
        BadRequestError: key missing on the request
        NotFoundError: object does not exist on the bucket
        e: _description_

    Returns:
        Dict[str, str]: pre-signed url
    """
    key = app.current_event.query_string_parameters.get("key")
    expiration = int(
        app.current_event.query_string_parameters.get(
            "expiration", str(DEFAULT_EXPIRATOIN)
        )
    )

    if key is None:
        raise BadRequestError("No key provided as query parameter")

    try:
        s3_client.head_object(Bucket=S3_BUCKET_NAME, Key=key)
    except botocore.exceptions.ClientError as e:
        if e.response["Error"]["Code"] == "404":
            raise NotFoundError("Key not found")
        else:
            raise

    s3_presigned_url = create_presigned_url(key, expiration)
    return {"s3_presigned_url": s3_presigned_url}


def lambda_handler(event: Dict[str, Any], context: LambdaContext) -> Any:
    """Lambda entrypoint.

    Args:
        event (Dict[str, Any]): event from the API GW
        context (LambdaContext): context of the lambda

    Returns:
        Any: API response
    """
    return app.resolve(event, context)
