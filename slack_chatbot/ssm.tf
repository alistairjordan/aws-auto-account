resource "aws_ssm_parameter" "slack_signing_secret" {
  name  = "slack_signing_secret"
  type  = "String"
  value = "ENTER ME HERE"
  overwrite = false
  lifecycle {
        ignore_changes = [ value ]
    }
}

resource "aws_ssm_parameter" "slack_hook_url" {
  name  = "slack_hook_url"
  type  = "String"
  value = "ENTER ME HERE"
  overwrite = false
  lifecycle {
        ignore_changes = [ value ]
    }
}

resource "aws_ssm_parameter" "slack_outbound_sns" {
  name  = "slack_outbound_sns"
  type  = "String"
  value = var.sns_outbound
  overwrite = false
  force_destroy = true
  lifecycle {
        ignore_changes = [ value ]
    }
}

resource "aws_ssm_parameter" "account_create_sns" {
  name  = "account_create_sns"
  type  = "String"
  value = var.sns_account_create
  overwrite = false
  lifecycle {
        ignore_changes = [ value ]
    }
}