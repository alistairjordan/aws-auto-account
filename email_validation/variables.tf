variable "email_domain" {
    type = string
}

variable "EmailVerificationSource" {
    type = string
    default = "EmailVerificationLambda"
}

variable "EmailVerificationLambdaPrefix" {
    type = string
    default = "EmailVerificationLambda"
}

variable "temp_directory" {
    type = string
    default = "/tmp"
}

variable "lambda_s3_bucket" {
    type = string
}