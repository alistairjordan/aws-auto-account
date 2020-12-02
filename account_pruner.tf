module "account_pruner" {
  source = "./account_pruner"
  sns_slack_outbound = aws_sns_topic.slack_outbound.arn
  lambda_s3_bucket = aws_s3_bucket.lambda_bucket.id
  backend_db = module.backend_database.table_arn
  backend_db_ssm = module.backend_database.ssm_table_arn
}