resource "aws_lambda_permission" "account_creation_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = replace(aws_lambda_function.account_creation.function_name, ":$LATEST", "")
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_account_creation
}

resource "aws_sns_topic_subscription" "account_creation_lambda" {
  topic_arn = var.sns_account_creation
  protocol  = "lambda"
  endpoint  = aws_lambda_function.account_creation.arn
}

# Check for any code changes
data "external" "account_creation_md5" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${path.module}/${var.AccountCreationLambdaSource} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}

# Zip the Lamda function on the fly
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/${var.AccountCreationLambdaSource}"
  output_path = "${var.temp_directory}/${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  depends_on = [ data.external.account_creation_md5 ]
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = var.lambda_s3_bucket
  key    = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  source = "${var.temp_directory}/${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  etag = filemd5(data.archive_file.source.output_path)
}

resource "aws_lambda_function" "account_creation" {
   function_name = "AccountCreation"

   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = var.lambda_s3_bucket
   s3_key    = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   role = aws_iam_role.account_creation_lambda_role.arn
   depends_on = [ aws_s3_bucket_object.file_upload ]
}

resource "aws_cloudwatch_log_group" "logs_account_creation" {
  name = "/aws/lambda/AccountCreation"
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "account_creation_lambda_role" {
   name = "AccountCreationLambda"

   assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment_outbound" {
  role       = aws_iam_role.account_creation_lambda_role.name
  policy_arn = aws_iam_policy.account_creation_lambda_policy.arn
}

resource "aws_iam_policy" "account_creation_lambda_policy" {
  name        = "AccountCreation"
  path        = "/"
  description = "My test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "${var.sns_slack_outbound}"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "${var.email_domain_ssm}",
      "Effect": "Allow"
    }
  ]
}
EOF
}