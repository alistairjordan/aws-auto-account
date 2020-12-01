module "email_validation" {
    source = "./email_validation"
    email_domain = var.email_domain
    lambda_s3_bucket = aws_s3_bucket.lambda_bucket.id
}