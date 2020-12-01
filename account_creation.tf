resource "aws_sns_topic" "account_creation" {
  name = "account_creation"
}

module "account_creation" {
  source = "./account_creation"
  sns_slack_outbound = aws_sns_topic.slack_outbound.arn
  sns_account_creation = aws_sns_topic.account_creation.arn
  lambda_s3_bucket = aws_s3_bucket.lambda_bucket.id
  email_domain_ssm = module.email_validation.email_domain_ssm
  backend_db = module.backend_database.table_arn
  backend_db_ssm = module.backend_database.ssm_table_arn
}