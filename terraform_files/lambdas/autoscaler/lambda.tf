# AutoScaler lambda

# Sets up the integration lambda for apigateway
data "archive_file" "auto_scaler" {
  type        = "zip"
  source_file = "${path.module}/../../../custom_runners/lambdas/autoscaler.py"
  output_path = "/tmp/custom_runners/lambdas/autoscaler_payload.zip"
}

resource "aws_lambda_function" "auto_scaler" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "/tmp/custom_runners/lambdas/autoscaler_payload.zip"
  function_name    = "AutoScaler"
  role             = aws_iam_role.auto_scaler.arn
  handler          = "autoscaler.lambda_handler"
  runtime          = "python3.10"
  timeout          = 900
  source_code_hash = data.archive_file.auto_scaler.output_base64sha256
  depends_on       = [aws_iam_role.auto_scaler]

  environment {
    variables = {
      GITHUB_SECRET       = var.github_secret_name
      GITHUB_EVENTS_QUEUE = var.sqs_url
    }
  }
}

resource "aws_cloudwatch_log_group" "auto_scaler" {
  name = "/aws/lambda/${aws_lambda_function.auto_scaler.function_name}"

  retention_in_days = 30
}