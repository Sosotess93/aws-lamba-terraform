import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    The Lambda handler function that gets invoked when the API endpoint is hit
    """

    d = {}

    if "body" in event:
        print("Found body in  event")
        data = json.loads(event["body"])
        d = data
        print("DATA = ", data)

    logger.info('## Input Parameters: %s', event)
    response = {
        "statusCode": 200,
        "body": json.dumps({'result': d}),
    }
    logger.info('## Response returned: %s', response)
    return response