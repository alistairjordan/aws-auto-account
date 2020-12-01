import os
import logging
import jsonpickle
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client('organizations')
ssm = boto3.client('ssm')
email_domain = ssm.get_parameter(Name='email_domain')['Parameter']['Value']


def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
    response = org.create_account(
        Email='string',
        AccountName='string',
        RoleName='string',
        IamUserAccessToBilling='ALLOW'|'DENY',
        Tags=[
            {
                'Key': 'string',
                'Value': 'string'
            },
        ]
        )
    print(response)
    print("TEST")
