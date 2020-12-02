import os
import logging
import jsonpickle
import boto3
import random
import datetime

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
    
    inbound_message = jsonpickle.decode(event["Records"][0]["Sns"]["Message"])
    logger.info('## Inbound message\r' + str(inbound_message))
    account_name = password_generator()
    email = account_name + "@" + email_domain
    password = password_generator()
    requestor = inbound_message["user"]
    time_delta = inbound_message["time"]
    created = datetime.datetime.now().timestamp()
    expires = created + time_delta
    
    logger.info('## Create account \nuser: '+ requestor+'\ntime_delta: '+str(time_delta)+'\nAccount Name: '+account_name+'\nEmail: '+email)
    logger.info('## Expiry time '+ str(expires) +' and in human readable is..'+ str(datetime.datetime.fromtimestamp(expires)))
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
### Required Data
# * Requesting User -
# * Creation Date
# * Deletion Date
# * Account Email -
# * Account Password -
# * Account Name - 
# * Account Number -
# * Status

    db.put_item(
    TableName=backend_db, 
    Item={
        'User':{'S': requestor},
        'Name':{'S':account_name},
        'Email':{'S':email},
        'Password':{'S':password},
        'Number':{'N':'0'},
        'Status':{'S':response["CreateAccountStatus"]["State"]}
    })
    print("TEST")
