module "slack_chatbot" {
    source = "./slack_chatbot"
    lambda_s3_bucket = aws_s3_bucket.lambda_bucket.id
    sns_inbound = aws_sns_topic.account_creation.arn
    sns_outbound = aws_sns_topic.slack_outbound.arn
    sns_account_create = aws_sns_topic.account_creation.arn
}

resource "aws_sns_topic" "slack_outbound" {
  name = "slack_outbound"
}

