import json
import boto3
import os
import base64
import urllib.parse
import datetime
import hashlib
import hmac

from botocore.signers import RequestSigner

s3 = boto3.client("s3")
eks = boto3.client("eks")
sts = boto3.client("sts")

def lambda_handler(event, context):
    # ---- Read CodePipeline artifact ----
    job = event["CodePipeline.job"]
    artifact = job["data"]["inputArtifacts"][0]
    location = artifact["location"]["s3Location"]

    obj = s3.get_object(
        Bucket=location["bucketName"],
        Key=location["objectKey"]
    )

    data = json.loads(obj["Body"].read().decode("utf-8"))
    image_uri = data["imageUri"]

    print("Image URI:", image_uri)

    # ---- Discover EKS cluster ----
    cluster_name = os.environ["CLUSTER_NAME"]
    region = os.environ["CLUSTER_REGION"]

    cluster_info = eks.describe_cluster(name=cluster_name)["cluster"]
    endpoint = cluster_info["endpoint"]
    ca_data = cluster_info["certificateAuthority"]["data"]

    print("EKS endpoint:", endpoint)
    print("CA data length:", len(ca_data))

    # ---- Generate Kubernetes auth token ----
    session = boto3.session.Session()
    service_id = 'sts'
    signer = RequestSigner(
        service_id,
        region,
        service_id,
        'v4',
        session.get_credentials(),
        session.events
    )

    params = {
        'method': 'GET',
        'url': f'https://sts.{region}.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15',
        'body': {},
        'headers': {'x-k8s-aws-id': cluster_name},
        'context': {}
    }

    signed_url = signer.generate_presigned_url(
        params,
        expires_in=60,
        operation_name=''
    )

    # Token for Kubernetes is base64url encoded URL with prefix
    token = 'k8s-aws-v1.' + base64.urlsafe_b64encode(signed_url.encode('utf-8')).decode('utf-8').rstrip('=')
    print("Kubernetes Auth Token:", token[:50] + '...')  # print first 50 chars

    return {
        "statusCode": 200,
        "body": "Token generation succeeded"
    }

