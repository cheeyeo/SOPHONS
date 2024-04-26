# CreateRunner lambda

data "archive_file" "create_runner" {
  type        = "zip"
  source_file = "${path.module}/../../../custom_runners/lambdas/create_runner.py"
  output_path = "/tmp/custom_runners/lambdas/create_runner_payload.zip"
}

resource "aws_lambda_function" "create_runner" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "/tmp/custom_runners/lambdas/create_runner_payload.zip"
  function_name = "CreateRunner"
  role          = aws_iam_role.create_runner.arn
  handler       = "create_runner.lambda_handler"
  runtime       = "python3.10"
  depends_on    = [aws_iam_role.create_runner]
  timeout       = 900
  # reserved_concurrent_executions = var.reserved_concurrency

  source_code_hash = data.archive_file.create_runner.output_base64sha256

  environment {
    variables = {
      GITHUB_TOKEN  = var.github_token_name
      SQS_QUEUE     = var.sqs_url
      RUNNER_SCRIPT = var.s3_runner_script_url
    }
  }
}

resource "aws_cloudwatch_log_group" "create_runner" {
  name = "/aws/lambda/${aws_lambda_function.create_runner.function_name}"

  retention_in_days = 30
}

# Create trigger to activate lambda from message in SQS
resource "aws_lambda_event_source_mapping" "runner" {
  event_source_arn = var.sqs_arn
  function_name    = aws_lambda_function.create_runner.arn
  batch_size       = var.batch_size

  enabled = var.enable_sqs_trigger
  # Below means that the event source mapping will delete successful messages and replay the failed ones..
  # The batch_item_failures is set in create_runner.py lambda
  function_response_types = ["ReportBatchItemFailures"]
  depends_on              = [aws_iam_role.create_runner]
}