import logging
import json
import os
import hashlib
import hmac
import base64
import time
from urllib.request import Request, urlopen
import boto3


# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-develop-integrations-lambda.html

logger = logging.getLogger("autoscaler")
logger.setLevel(logging.INFO)


GITHUB_SECRET = os.environ.get('GITHUB_SECRET')


def lambda_handler(event, context):
    logger.info(json.dumps(event, indent=2))
    logger.info("Running signature check...")
    
    try:
        verify_signature(event)
    except Exception as e:
        return {
            "isBase64Encoded": False,
            "statusCode": 403,
            "body": e.args
        }
        
     # check what type of action it is: queued, in_progress, completed
    body = json.loads(event['body'])
    event_header = event['headers']['x-github-event']
    action = body.get('action', None)

    if action == 'queued' and event_header == 'workflow_job':
        logger.info('New job created. Installing runner...')
        
        sqs = boto3.client("sqs")
        resp = sqs.send_message(
            QueueUrl=os.environ.get('GITHUB_EVENTS_QUEUE'),
            MessageBody=event['body']
        )
        
        logger.info(f'SQS MESSAGE ID: {resp["MessageId"]}')
            
        return {
            "isBase64Encoded": False,
            "statusCode": 200,
            "body": 'Runners created'
        }
    elif action == 'completed' and event_header == 'workflow_job':
        instance_id = body.get('workflow_job', dict()).get('runner_name')

        logger.info(f'Job completed for runner {instance_id}')

        return {
            "isBase64Encoded": False,
            "statusCode": 200,
            "body": f"Job completed. Instance {instance_id} deleted"
        }
    elif event_header == 'ping':
       logger.info('Ping message received...')
       return {
            "isBase64Encoded": False,
            "statusCode": 200,
            "body": "PING Message received"
        }
    else:
        return {
            "isBase64Encoded": False,
            "statusCode": 200,
            "body": "JOB IS RUNNING. NOTHING TO DO..."
        }


def verify_signature(event):
    if 'x-hub-signature-256' not in event['headers'].keys():
        raise Exception("x-hub-signature-256 is missing!")
    
    client = boto3.client('ssm')

    try:
        response = client.get_parameter(
            Name=GITHUB_SECRET,
            WithDecryption=True
        )
    except Exception as e:
        logger.debug(e.response)
        raise Exception('GITHUB_SECRET cannot be retrieved')

    github_secret = response["Parameter"]["Value"]
    github_signature = event['headers']['x-hub-signature-256']

    body = event.get('body', '')
    if event['isBase64Encoded'] == "true":
        body = base64.b64decode(body)

    hashsum = hmac.new(github_secret.encode('utf-8'), body.encode('utf-8'), digestmod=hashlib.sha256).hexdigest()
    
    expected_signature = f"sha256={hashsum}"

    logger.info(expected_signature)
    logger.info(github_signature)
    
    if not hmac.compare_digest(expected_signature, github_signature):
        raise Exception("Request signatures don't match")
