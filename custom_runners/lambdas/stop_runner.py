import json
import os
import time
import logging
from urllib.request import Request, urlopen
import boto3


logger = logging.getLogger("scale-in")
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info('INSIDE STOP RUNNER')
    logger.info(event)

    status = event['detail']['status']
    document = event['detail']['document-name']
    instance_id = event['detail']['instance-id']
    region = event['region']

    if document == 'AWS-RunRemoteScript' and status in ['Failed', 'Success']:
        logger.info(f'Runner script completed. Status: {status} Runner : {instance_id}')

        terminate_instance(instance_id, region)


def terminate_instance(instance_id, region):
    client = boto3.client('ec2', region_name=region)
    response = client.terminate_instances(
        InstanceIds=[
            instance_id,
        ],
        DryRun=False
    )

    logger.info(response)

    ec2 = boto3.resource('ec2')
    instance = ec2.Instance(instance_id)
    response = client.cancel_spot_instance_requests(
        SpotInstanceRequestIds=[instance.spot_instance_request_id]
    )

    logger.info(f'CANCEL SPOT INSTANCE: {response}')