import os
import logging
import boto3
import jsonpickle
import hmac
import hashlib
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns = boto3.client('sns')
ssm = boto3.client('ssm')
slack_signing_secret = ssm.get_parameter(Name='slack_signing_secret')['Parameter']['Value']
slack_outbound_sns = ssm.get_parameter(Name='slack_outbound_sns')['Parameter']['Value']
account_create_sns = ssm.get_parameter(Name='account_create_sns')['Parameter']['Value']
print(slack_signing_secret)

def verify_token(token, timestamp, signature, body, secret):
    if abs(time.time() - int(timestamp)) > 60 * 5:
        print("Possible replay attack!!")
        return False
    sig_basestring = 'v0:' + timestamp + ':' + body
    my_signature = 'v0=' + hmac.new(secret.encode('UTF-8'), sig_basestring.encode('UTF-8'), hashlib.sha256).hexdigest()
    print(my_signature + "      " + signature)
    if my_signature == signature:
        return True
    else:
        return False

def send_message_sns(text,sns):
    response = sns.publish(
    TopicArn=slack_outbound_sns,    
    Message=text,    
    )
    
def help(data):
    text = "Hi there, I don't understand what you want"
    send_message_sns(text,slack_outbound_sns)

def create(data):
    text = "I'm going to try and create this for you"
    send_message(text,slack_outbound_sns)
    send_message(data,account_create_sns)
    
def process_command(data):
    data2 = data.split()
    command = data2[1]
    content = data2[2:]
    if data2[1] == "help":
        help(content)
    elif data2[1] == "create":
        create(content)
    else:
        help(content)
    
def lambda_handler(event, context):
    logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    logger.info('## CONTEXT\r' + jsonpickle.encode(context))
    body = jsonpickle.decode(event["body"])
    slack_time_stamp = event["headers"]["x-slack-request-timestamp"]
    slack_signature = event["headers"]["x-slack-signature"]
    print(body)
    if not verify_token(body["token"],slack_time_stamp,slack_signature,event["body"],slack_signing_secret):
        raise Exception('Not Auth\'d')
    if body["event"]["type"] == "app_mention":
        data = body["event"]["text"]
        process_command(data)
    print(data)
    return event
    