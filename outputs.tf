output "email_verification_record" {
    value = "_amazonses.${var.email_domain}:TXT:${module.email_validation.ses_verification_token}"
    description = "Add this as a TXT record to DNS at _amazonses.email_domain.com"   
}