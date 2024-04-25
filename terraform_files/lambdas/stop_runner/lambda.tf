# Stop runners lambda

data "archive_file" "stop_runner" {
  type        = "zip"
  source_file = "${path.module}/../../../custom_runners/lambdas/stop_runner.py"
  output_path = "/tmp/custom_runners/lambdas/stop_runner_payload.zip"
}

resource "aws_lambda_function" "stop_runner" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "/tmp/custom_runners/lambdas/stop_runner_payload.zip"
  function_name    = "StopRunner"
  role             = aws_iam_role.stop_runner.arn
  handler          = "stop_runner.lambda_handler"
  runtime          = "python3.10"
  depends_on       = [aws_iam_role.stop_runner]
  timeout          = 900
  source_code_hash = data.archive_file.stop_runner.output_base64sha256

  environment {
    variables = {
      GITHUB_TOKEN = var.github_token_name
    }
  }
}

resource "aws_cloudwatch_log_group" "stop_runner" {
  name = "/aws/lambda/${aws_lambda_function.stop_runner.function_name}"

  retention_in_days = 30
}


# Create event bridge trigger to delete ec2 if runner script fails or job completed
resource "aws_cloudwatch_event_rule" "stop_runner" {
  name          = "StopRunner"
  is_enabled    = var.enable_stop_runner
  event_pattern = <<PATTERN
{
  "source": ["aws.ssm"],
  "detail-type": ["EC2 Command Invocation Status-change Notification"],
  "detail": {
    "status": ["Failed", "Success"]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "stop_runner" {
  rule = aws_cloudwatch_event_rule.stop_runner.name
  arn  = aws_lambda_function.stop_runner.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_delete" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_runner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_runner.arn
}