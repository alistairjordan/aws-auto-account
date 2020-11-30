import os
import logging
import jsonpickle
import boto3
import urllib3
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm = boto3.client('ssm')
slack_hook_url = ssm.get_parameter(Name='slack_hook_url')['Parameter']['Value']
print(slack_hook_url)

def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
    for record in event["Records"]:
        text = record["Sns"]["Message"]
        http = urllib3.PoolManager()
        encoded_body = json.dumps({
            "text": text
        })
        r = http.request('POST', slack_hook_url,
                     headers={'Content-Type': 'application/json'},
                     body=encoded_body)
        print(event)
    print(r.read())
    return event