resource "aws_ses_domain_identity" "ses_email_domain" {
  domain = var.email_domain
}

resource "aws_ses_receipt_rule" "store" {
  name          = "email_inbound"
  rule_set_name = "email-verification-rules"
  enabled       = true
  scan_enabled  = true

  sns_action {
    topic_arn = aws_sns_topic.email_validation.arn
    position = 1
  }
}

resource "aws_ses_receipt_rule_set" "main" {
  rule_set_name = "email-verification-rules"
}

resource "aws_ses_active_receipt_rule_set" "main" {
  rule_set_name = "email-verification-rules"
}

# data "aws_iam_policy_document" "email_validation" {
#   statement {
#     actions   = ["SES:SendEmail", "SES:SendRawEmail"]
#     resources = [aws_ses_domain_identity.email_validation.arn]

#     principals {
#       identifiers = ["*"]
#       type        = "AWS"
#     }
#   }
# }

# resource "aws_ses_identity_policy" "example" {
#   identity = aws_ses_domain_identity.ses_email_domain.arn
#   name     = "Email_validation policy"
#   policy   = data.aws_iam_policy_document.email_validation.json
# }