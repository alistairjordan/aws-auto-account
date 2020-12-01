resource "aws_ssm_parameter" "backend_database" {
  name  = "backend_database"
  type  = "String"
  value = aws_dynamodb_table.backend_database.id
  overwrite = false
  lifecycle {
        ignore_changes = [ value ]
    }
}