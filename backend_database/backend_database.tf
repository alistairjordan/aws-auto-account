resource "aws_dynamodb_table" "backend_database" {
  name           = "AWSAccounts"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "User"

  attribute {
    name = "User"
    type = "S"
  }

#   attribute {
#     name = "Creation"
#     type = "N"
#   }

#   attribute {
#     name = "Deletion"
#     type = "N"
#   }

#   attribute {
#     name = "Email"
#     type = "S"
#   }
#   attribute {
#     name = "Password"
#     type = "S"
#   }
#   attribute {
#     name = "Name"
#     type = "S"
#   }
#   attribute {
#     name = "Number"
#     type = "N"
#   }

}