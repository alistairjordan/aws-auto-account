# Check for any code changes
data "external" "account_pruner_md5" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${path.module}/${var.AccountPrunerLambdaSource} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}

# Zip the Lamda function on the fly
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/${var.AccountPrunerLambdaSource}"
  output_path = "${var.temp_directory}/${var.AccountPrunerLambdaPrefix}${data.external.account_pruner_md5.result.md5}.zip"
  depends_on = [ data.external.account_pruner_md5 ]
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = var.lambda_s3_bucket
  key    = "${var.AccountPrunerLambdaPrefix}${data.external.account_pruner_md5.result.md5}.zip"
  source = "${var.temp_directory}/${var.AccountPrunerLambdaPrefix}${data.external.account_pruner_md5.result.md5}.zip"
  etag = filemd5(data.archive_file.source.output_path)
}

resource "aws_lambda_function" "account_pruner" {
   function_name = "AccountPruner"

   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = var.lambda_s3_bucket
   s3_key    = "${var.AccountPrunerLambdaPrefix}${data.external.account_pruner_md5.result.md5}.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   timeout = 64

   role = aws_iam_role.account_pruner_lambda_role.arn
   depends_on = [ aws_s3_bucket_object.file_upload ]
}

resource "aws_cloudwatch_log_group" "logs_account_pruner" {
  name = "/aws/lambda/AccountPruner"
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "account_pruner_lambda_role" {
   name = "AccountPrunerLambda"

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

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment" {
  role       = aws_iam_role.account_pruner_lambda_role.name
  policy_arn = aws_iam_policy.account_pruner_lambda_policy.arn
}

resource "aws_iam_policy" "account_pruner_lambda_policy" {
  name        = "AccountPruner"
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
        "organizations:*"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "${var.backend_db_ssm}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "dynamodb:BatchGetItem",
				"dynamodb:GetItem",
				"dynamodb:Query",
				"dynamodb:Scan",
				"dynamodb:BatchWriteItem",
				"dynamodb:PutItem",
				"dynamodb:UpdateItem"
      ],
      "Resource": "${var.backend_db}",
      "Effect": "Allow"
    }
  ]
}
EOF
}