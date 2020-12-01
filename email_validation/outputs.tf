output "ses_verification_token" {
    value = aws_ses_domain_identity.ses_email_domain.verification_token
    description = "Add this as a TXT record to DNS at _amazonses.email_domain.com"
}

output "email_domain_ssm" {
    value = aws_ssm_parameter.email_verification_domain.arn
}