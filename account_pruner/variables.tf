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

variable "AccountPrunerLambdaSource" {
    type = string
    default = "AccountPrunerLambda"
}

variable "AccountPrunerLambdaPrefix" {
    type = string
    default = "AccountPrunerLambda"
}

variable "backend_db_ssm" {
    type = string
}

variable "backend_db" {
    type = string
}