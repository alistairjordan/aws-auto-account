resource "aws_ssm_parameter" "email_verification_domain" {
  name  = "email_verification_domain"
  type  = "String"
  value = var.email_domain
  overwrite = false
  lifecycle {
        ignore_changes = [ value ]
    }
}