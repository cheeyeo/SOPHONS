import logging
import json
import os
import hashlib
import hmac


logger = logging.getLogger("httpapi-auth")
logger.setLevel(logging.INFO)


# NOTE: This is an authorizer used by api gateway
# It only returns a simple boolean value
# https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html
def lambda_handler(event, context):
    logger.info(json.dumps(event, indent=2))

    is_authorized = checkHeaders(event['headers'])

    state = {
        "isAuthorized": is_authorized,
        "context": {}
    }

    logger.info(state)

    return state


def checkHeaders(headers):
    if not headers['user-agent'].startswith('GitHub-Hookshot'):
        return False

    if 'x-hub-signature-256' not in headers:
        return False

    return True