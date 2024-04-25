# Sets up the authorizer lambda for api gateway

data "archive_file" "webhook_authorizer" {
  type        = "zip"
  source_file = "${path.module}/../../../custom_runners/lambdas/webhook_authorizer.py"
  output_path = "/tmp/custom_runners/lambdas/webhook_authorizer_payload.zip"
}

resource "aws_lambda_function" "auth_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "/tmp/custom_runners/lambdas/webhook_authorizer_payload.zip"
  function_name = "GithubWebhookAuthorizer2"
  role          = aws_iam_role.github_webhook_authorizer.arn
  handler       = "webhook_authorizer.lambda_handler"
  runtime       = "python3.10"
  depends_on    = [aws_iam_role.github_webhook_authorizer]

  environment {
    variables = {
      name = "gh-runner"
    }
  }
}

resource "aws_cloudwatch_log_group" "auth_lambda" {
  name = "/aws/lambda/${aws_lambda_function.auth_lambda.function_name}"

  retention_in_days = 30
}