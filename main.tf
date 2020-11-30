resource "aws_sns_topic" "account_creation" {
  name = "account_creation"
}

resource "aws_lambda_permission" "outbound_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = replace(aws_lambda_function.account_creation.function_name, ":$LATEST", "")
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.account_creation.arn
}

resource "aws_sns_topic_subscription" "account_creation_lambda" {
  topic_arn = aws_sns_topic.account_creation.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.account_creation.arn
}

# Check for any code changes
data "external" "account_creation_md5" {
  program = ["bash", "-c",<<EOF
  echo "{\"md5\":\"$(tar -cf - ${var.AccountCreationLambdaSource} | md5sum | awk '{print $1}')\"}"
  EOF 
  ]
}

# Zip the Lamda function on the fly
data "archive_file" "source" {
  type        = "zip"
  source_dir  = var.AccountCreationLambdaSource
  output_path = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  depends_on = [ data.external.account_creation_md5 ]
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  source = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"
  depends_on = [ aws_s3_bucket.lambda_bucket]
  etag = filemd5(data.archive_file.source.output_path)
}

resource "aws_lambda_function" "account_creation" {
   function_name = "AccountCreation"

   # The bucket name as created earlier with "aws s3api create-bucket"
   s3_bucket = aws_s3_bucket.lambda_bucket.id
   s3_key    = "${var.AccountCreationLambdaPrefix}${data.external.account_creation_md5.result.md5}.zip"

   # "main" is the filename within the zip file (main.js) and "handler"
   # is the name of the property under which the handler function was
   # exported in that file.
   handler = "main.handler"
   runtime = "python3.8"

   role = aws_iam_role.account_creation_lambda_role.arn
   depends_on = [ aws_s3_bucket_object.file_upload ]
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