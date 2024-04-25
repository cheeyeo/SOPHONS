output "lambda_arn" {
  value = aws_lambda_function.auto_scaler.arn
}

output "invoke_arn" {
  value = aws_lambda_function.auto_scaler.invoke_arn
}