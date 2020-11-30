resource "aws_apigatewayv2_api" "slack_inbound" {
  name          = "SlackInbound"
  protocol_type = "HTTP"
  target = aws_lambda_function.slack_integration_inbound.arn
}

# resource "aws_apigatewayv2_integration" "slack_inbound" {
#   api_id           = aws_apigatewayv2_api.slack_inbound.id
#   integration_type = "AWS"

#   connection_type           = "INTERNET"
#   content_handling_strategy = "CONVERT_TO_TEXT"
#   description               = "Lambda example"
#   integration_method        = "POST"
#   integration_uri           = aws_lambda_function.slack_integration_inbound.arn
#   passthrough_behavior      = "WHEN_NO_MATCH"
# }

# Permission
resource "aws_lambda_permission" "apigw" {
	action        = "lambda:InvokeFunction"
	function_name = aws_lambda_function.slack_integration_inbound.arn
	principal     = "apigateway.amazonaws.com"

	source_arn = "${aws_apigatewayv2_api.slack_inbound.execution_arn}/*/*"
}