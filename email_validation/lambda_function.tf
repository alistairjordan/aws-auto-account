

# Check for any code changes
data "external" "email_verification_md5" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${path.module}/${var.EmailVerificationSource} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}

# Zip the Lamda function on the fly
data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/${var.EmailVerificationSource}"
  output_path = "${var.temp_directory}/${var.EmailVerificationLambdaPrefix}${data.external.email_verification_md5.result.md5}.zip"
  depends_on = [ data.external.email_verification_md5 ]
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = var.lambda_s3_bucket
  key    = "${var.EmailVerificationLambdaPrefix}${data.external.email_verification_md5.result.md5}.zip"
  source = "${var.temp_directory}/${var.EmailVerificationLambdaPrefix}${data.external.email_verification_md5.result.md5}.zip"
  etag = filemd5(data.archive_file.source.output_path)
}

resource "aws_lambda_function" "email_verification" {
   function_name = "EmailVerification"

   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = var.lambda_s3_bucket
   s3_key    = "${var.EmailVerificationLambdaPrefix}${data.external.email_verification_md5.result.md5}.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "lambda_function.lambda_handler"
   runtime = "python3.8"

   role = aws_iam_role.email_verification_lambda_role.arn
   depends_on = [ aws_s3_bucket_object.file_upload ]
}

resource "aws_cloudwatch_log_group" "logs_email_verification" {
  name = "/aws/lambda/EmailVerification"
}

 # IAM role which dictates what other AWS services the Lambda function
 # may access.
resource "aws_iam_role" "email_verification_lambda_role" {
   name = "EmailVerificationLambda"

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
  role       = aws_iam_role.email_verification_lambda_role.name
  policy_arn = aws_iam_policy.email_verification_lambda_policy.arn
}

resource "aws_iam_policy" "email_verification_lambda_policy" {
  name        = "EmailVerification"
  path        = "/"
  description = "My test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_sns_topic_subscription" "email_verification_sns_sub" {
  topic_arn = aws_sns_topic.email_validation.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification.arn
}

resource "aws_lambda_permission" "email_verification_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = replace(aws_lambda_function.email_verification.function_name, ":$LATEST", "")
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.email_validation.arn
}