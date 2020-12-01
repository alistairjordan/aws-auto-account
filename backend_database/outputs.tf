output "table_arn" {
    value = aws_dynamodb_table.backend_database.arn
}

output "ssm_table_arn" {
    value = aws_ssm_parameter.backend_database.arn
}