import logging
import json
import os
import boto3
import time
from botocore.config import Config


logger = logging.getLogger("create_runner")
logger.setLevel(logging.INFO)


QUEUE_URL = os.environ.get('SQS_QUEUE')
GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN')
RUNNER_SCRIPT = os.environ.get('RUNNER_SCRIPT')


def lambda_handler(event, context):
    logger.debug(f'EVENT: {event}')

    # Uses partial batch responses
    # https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html#services-sqs-batchfailurereporting
    batch_item_failures = []
    sqs_batch_response = {}

    for msg in event['Records']:
        logger.info(f'SQS MSG: {msg}')

        body = json.loads(msg['body'])
        workflow_id = body.get('workflow_job').get('run_id')
        runner_labels = body.get('workflow_job').get('labels')
        template_name = list(filter(lambda x: "template" in x, runner_labels))[0]
        repo_owner = body.get('repository').get('name')
        repo_name = body.get('repository').get('owner').get('login')
        repo_branch = body.get('workflow_job').get('head_branch')
        
        logger.info(f'BODY: {body}')
        logger.info(f'WORKFLOW ID: {workflow_id}')
        logger.info(f'LABELS: {runner_labels}')
        logger.info(f'TEMPLATE: {template_name}')
    
        client = boto3.client('ec2')
        resp = client.create_fleet(
            SpotOptions={
                'AllocationStrategy': 'price-capacity-optimized'
            },
            LaunchTemplateConfigs=[
                {
                    'LaunchTemplateSpecification': {
                        'LaunchTemplateName': template_name,
                        'Version': '$Default'
                    }
                }
            ],
            TargetCapacitySpecification={
                'TotalTargetCapacity': 1,
                'DefaultTargetCapacityType': 'spot',
                'SpotTargetCapacity': 1,
            },
            Type='instant',
            TagSpecifications=[
                {
                    'ResourceType': 'instance',
                    'Tags': [
                        {
                            'Key': 'template_name',
                            'Value': template_name
                        },
                        {
                            'Key': 'self-hosted-runner',
                            'Value': 'github'
                        },
                        {
                            'Key': 'github-owner',
                            'Value': repo_owner
                        },
                        {
                            'Key': 'github-repo',
                            'Value': repo_name
                        }
                    ]
                }
            ]
        )
        
        logger.info(resp)

        # TODO: Return here if there's an error like vcpu quota exceeded
        errors = resp.get('Errors', [])
        if len(errors) > 0:
            err_code = errors[0]['ErrorCode']
            err_msg = errors[0]['ErrorMessage']
            logger.error(f'Error with creating instance: Error Code: {err_code}, Error Message: {err_msg}')

            batch_item_failures.append({
                "itemIdentifier": msg['messageId']
            })

            continue # move to next msg


        instance_id = resp['Instances'][0]['InstanceIds'][0]
        logger.info(f"INSTANCE ID: {instance_id}")

        if instance_id:
            ec2 = boto3.client('ec2')
            waiter = ec2.get_waiter('instance_status_ok')
            waiter.wait(
                InstanceIds=[instance_id]
            )
            
            logger.info(f'Instance {instance_id} created and running')
            
            command_id = run_ssm_document(instance_id, template_name, repo_owner, repo_name, repo_branch)
            logger.info(f"Document Run: {command_id}")

    
        # Delete SQS message from queue
        receipt_handle = msg['receiptHandle']
        sqs = boto3.client("sqs")
        resp = sqs.delete_message(
            QueueUrl=QUEUE_URL,
            ReceiptHandle=receipt_handle
        )
        logger.info(resp)

    sqs_batch_response["batchItemFailures"] = batch_item_failures
    return sqs_batch_response


def run_ssm_document(instance_id, template_name, repo_name, repo_owner, repo_branch):
    client = boto3.client('ssm')
    
    gh_token = client.get_parameter(
        Name=GITHUB_TOKEN,
        WithDecryption=True
    )["Parameter"]["Value"]
    
    source_info = {
        "path": RUNNER_SCRIPT
    }

    response = client.send_command(
        InstanceIds=[
            instance_id,
        ],
        DocumentName="AWS-RunRemoteScript",
        TimeoutSeconds=3600,
        Comment='Create Runners',
        Parameters={
            "sourceType":["S3"],
            "sourceInfo": [json.dumps(source_info)],
            "commandLine": [f"sudo chown ubuntu:ubuntu /tmp/jit_runner.sh && sudo runuser -l ubuntu -c 'GITHUB_PERSONAL_TOKEN={gh_token} GITHUB_OWNER={repo_owner} GITHUB_REPOSITORY={repo_name} /tmp/jit_runner.sh -n gh-runner-{instance_id} -l {template_name} -l self-hosted -l Linux -l x64'"],
            "workingDirectory":["/tmp"],
            "executionTimeout":["3600"]
        },
        CloudWatchOutputConfig={
            'CloudWatchLogGroupName': "/aws/ssm/runner_logs",
            'CloudWatchOutputEnabled': True
        },
    )

    logger.info(response)
    return response['Command']['CommandId']