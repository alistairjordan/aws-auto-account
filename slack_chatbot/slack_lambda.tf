# Check for any code changes
data "external" "slack_integration_md5_inbound" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${path.module}/${var.SlackLambdaSourceInbound} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}
data "external" "slack_integration_md5_outbound" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${path.module}/${var.SlackLambdaSourceOutbound} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}

# Zip the Lamda function on the fly
data "archive_file" "source_inbound" {
  type        = "zip"
  source_dir  = "${path.module}/${var.SlackLambdaSourceInbound}"
  output_path = "${var.temp_directory}/${var.SlackLambdaPrefixInbound}${data.external.slack_integration_md5_inbound.result.md5}.zip"
  depends_on = [ data.external.slack_integration_md5_inbound ]
}
data "archive_file" "source_outbound" {
  type        = "zip"
  source_dir  = "${path.module}/${var.SlackLambdaSourceOutbound}"
  output_path = "${var.temp_directory}/${var.SlackLambdaPrefixOutbound}${data.external.slack_integration_md5_outbound.result.md5}.zip"
  depends_on = [ data.external.slack_integration_md5_outbound ]
}

# Upload lambda functions
resource "aws_s3_bucket_object" "file_upload_inbound" {
  bucket = var.lambda_s3_bucket
  key    = "${var.SlackLambdaPrefixInbound}${data.external.slack_integration_md5_inbound.result.md5}.zip"
  source = "${var.temp_directory}/${var.SlackLambdaPrefixInbound}${data.external.slack_integration_md5_inbound.result.md5}.zip"
  etag = filemd5(data.archive_file.source_inbound.output_path)
}
resource "aws_s3_bucket_object" "file_upload_outbound" {
  bucket = var.lambda_s3_bucket
  key    = "${var.SlackLambdaPrefixOutbound}${data.external.slack_integration_md5_outbound.result.md5}.zip"
  source = "${var.temp_directory}/${var.SlackLambdaPrefixOutbound}${data.external.slack_integration_md5_outbound.result.md5}.zip"
  etag = filemd5(data.archive_file.source_outbound.output_path)
}

resource "aws_lambda_function" "slack_integration_inbound" {
   function_name = "SlackIntegrationInbound"

   s3_bucket = var.lambda_s3_bucket
   s3_key    = "${var.SlackLambdaPrefixInbound}${data.external.slack_integration_md5_inbound.result.md5}.zip"

   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   timeout = 64

   role = aws_iam_role.slack_integration_lambda_role_inbound.arn
   depends_on = [ aws_s3_bucket_object.file_upload_inbound ]
}
resource "aws_lambda_function" "slack_integration_outbound" {
   function_name = "SlackIntegrationOutbound"

   s3_bucket = var.lambda_s3_bucket
   s3_key    = "${var.SlackLambdaPrefixOutbound}${data.external.slack_integration_md5_outbound.result.md5}.zip"

   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   timeout = 64

   role = aws_iam_role.slack_integration_lambda_role_outbound.arn
   depends_on = [ aws_s3_bucket_object.file_upload_outbound ]
}

resource "aws_cloudwatch_log_group" "logs_inbound" {
  name = "/aws/lambda/SlackIntegrationInbound"
}

resource "aws_cloudwatch_log_group" "logs_outbound" {
  name = "/aws/lambda/SlackIntegrationOutbound"
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "slack_integration_lambda_role_inbound" {
   name = "SlackIntegrationLambdaInbound"

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
resource "aws_iam_role" "slack_integration_lambda_role_outbound" {
   name = "SlackIntegrationLambdaOutbound"

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

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment_inbound" {
  role       = aws_iam_role.slack_integration_lambda_role_inbound.name
  policy_arn = aws_iam_policy.slack_lambda_exec_policy_inbound.arn
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attachment_outbound" {
  role       = aws_iam_role.slack_integration_lambda_role_outbound.name
  policy_arn = aws_iam_policy.slack_lambda_exec_policy_outbound.arn
}

resource "aws_iam_policy" "slack_lambda_exec_policy_inbound" {
  name        = "SlackIntegrationLambdaInbound"
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
      "Resource": "${var.sns_inbound}"
    },
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "${var.sns_outbound}"
    },
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "${var.sns_account_create}"
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
      "Resource": "${aws_ssm_parameter.slack_signing_secret.arn}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "${aws_ssm_parameter.slack_outbound_sns.arn}",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ssm:GetParameter*"
      ],
      "Resource": "${aws_ssm_parameter.account_create_sns.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "slack_lambda_exec_policy_outbound" {
  name        = "SlackIntegrationLambdaOutbound"
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
      "Resource": "${var.sns_outbound}"
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
      "Resource": "${aws_ssm_parameter.slack_hook_url.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "slack_outbound_sns_sub" {
  topic_arn = var.sns_outbound
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_integration_outbound.arn
}

resource "aws_lambda_permission" "outbound_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = replace(aws_lambda_function.slack_integration_outbound.function_name, ":$LATEST", "")
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_outbound
}