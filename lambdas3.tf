resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "alistair-lambda-bucket"
  acl    = "private"
  force_destroy = true
  tags = {
    Name        = "Lambda bucket"
    Environment = "Dev"
  }
}