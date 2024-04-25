# Moves DLQ messages back to main queue
# Messages in DLQ are job events that errored out 3 times due to max capacity request
# or other errors for retries

import os
import logging
import json
import boto3


logger = logging.getLogger('move_jobs')
logger.setLevel(logging.INFO)


SOURCE_QUEUE_ARN = os.environ.get('SOURCE_QUEUE_ARN')
DESTINATION_QUEUE_ARN = os.environ.get('DESTINATION_QUEUE_ARN')


def lambda_handler(event, context):
    client = boto3.client('sqs')
    
    try:
        response = client.start_message_move_task(
            SourceArn=SOURCE_QUEUE_ARN,
            DestinationArn=DESTINATION_QUEUE_ARN,
            MaxNumberOfMessagesPerSecond=10
        )

        logger.info(f'Task Handle: {response["TaskHandle"]}')
    except client.exceptions.ResourceNotFoundException as error:
        logger.warn('SQS queue not found!')
    except client.exceptions.UnsupportedOperation as error:
        logger.warn('SQS operation not supported!')
    except Exception as e:
        logger.warn(f'Error: {e}')

    return 'Move jobs completed'