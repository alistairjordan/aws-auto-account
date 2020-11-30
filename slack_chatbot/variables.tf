variable "lambda_s3_bucket" {
  type = string
}

variable "SlackLambdaSourceInbound" {
    type = string
    default = "SlackLambdaInbound"
}
variable "SlackLambdaSourceOutbound" {
    type = string
    default = "SlackLambdaOutbound"
}

variable "SlackLambdaPrefixInbound" {
    type = string
    default = "SlackLambdaInbound"
}
variable "SlackLambdaPrefixOutbound" {
    type = string
    default = "SlackLambdaOutbound"
}

variable "temp_directory" {
    type = string
    default = "/tmp"
}

variable "sns_inbound" {
    type = string
}

variable "sns_outbound" {
    type = string
}

variable "sns_account_create" {
    type = string
}