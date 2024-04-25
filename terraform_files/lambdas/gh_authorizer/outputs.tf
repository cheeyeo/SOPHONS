output "lambda_arn" {
  value = aws_lambda_function.auth_lambda.arn
}

output "invoke_arn" {
  value = aws_lambda_function.auth_lambda.invoke_arn
}