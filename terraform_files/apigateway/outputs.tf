output "apigateway_url" {
  value = aws_apigatewayv2_stage.dev.invoke_url
}

output "apigateway_url_default" {
  value = aws_apigatewayv2_stage.default.invoke_url
}