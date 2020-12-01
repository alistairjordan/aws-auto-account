variable "sns_account_creation" {
    type = string
}

variable "temp_directory" {
    type = string
    default = "/tmp"
}

variable "lambda_s3_bucket" {
  type = string
}

variable "sns_slack_outbound" {
    type = string
}

variable "AccountCreationLambdaSource" {
    type = string
    default = "AccountCreationLambda"
}

variable "AccountCreationLambdaPrefix" {
    type = string
    default = "AccountCreationLambda"
}

variable "email_domain_ssm" {
    type = string
}

variable "backend_db" {
    type = string
}