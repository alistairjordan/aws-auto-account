import os
import logging
import jsonpickle
import boto3
import random

logger = logging.getLogger()
logger.setLevel(logging.INFO)

org = boto3.client('organizations')
ssm = boto3.client('ssm')
db = boto3.client('dynamodb')

email_domain = ssm.get_parameter(Name='email_verification_domain')['Parameter']['Value']
backend_db = ssm.get_parameter(Name='backend_database')['Parameter']['Value']

def password_generator(length=8):
    possible_chars = "QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890"
    current=""
    while not (any(c.islower() for c in current) and any(c.isupper() for c in current) and any(c. isnumeric() for c in current)):
        selected = []
        for i in range(length):
            selected.append(random.choice(possible_chars))
        current = ''.join(selected)
    return current
    


def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
    account_name = password_generator()
    email = account_name + "@" + email_domain
    password = password_generator()
    print("Creating account " + account_name + " email " + email)

    response = org.create_account(
        Email=email,
        AccountName=account_name,
        IamUserAccessToBilling='ALLOW',
        Tags=[
            {
                'Key': 'string',
                'Value': 'string'
            },
        ]
        )
    print(response)
    dynamodb.put_item(
    TableName=backend_db, 
    Item={
        'name':{'S':account_name},
        'email':{'S':email},
        'password':{'S':email},
        #'dad':{'N':'value2'}
    })
    print("TEST")
