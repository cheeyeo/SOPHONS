# PoolJobs lambda

# Setsup the lambda that checks if min number of runners are running
data "archive_file" "move_jobs" {
  type        = "zip"
  source_file = "${path.module}/../../../custom_runners/lambdas/move_jobs_runner.py"
  output_path = "/tmp/custom_runners/lambdas/move_jobs_payload.zip"
}

resource "aws_lambda_function" "move_jobs" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "/tmp/custom_runners/lambdas/move_jobs_payload.zip"
  function_name    = "MoveJobs"
  role             = aws_iam_role.move_jobs.arn
  handler          = "move_jobs_runner.lambda_handler"
  runtime          = "python3.10"
  depends_on       = [aws_iam_role.move_jobs]
  timeout          = 900
  source_code_hash = data.archive_file.move_jobs.output_base64sha256

  environment {
    variables = {
      SOURCE_QUEUE_ARN      = var.source_queue_arn
      DESTINATION_QUEUE_ARN = var.destination_queue_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "move_jobs" {
  name = "/aws/lambda/${aws_lambda_function.move_jobs.function_name}"

  retention_in_days = 30
}

# Create event bridge rule trigger to run lambda every 60 mins
resource "aws_cloudwatch_event_rule" "schedule_pool" {
  name                = "ScheduledPool"
  schedule_expression = "rate(60 minutes)"
  is_enabled          = var.enable_pool_scheduler
}

resource "aws_cloudwatch_event_target" "schedule_pool" {
  rule = aws_cloudwatch_event_rule.schedule_pool.name
  arn  = aws_lambda_function.move_jobs.arn
}

# Create trigger to activate lambda
resource "aws_lambda_permission" "allow_cloudwatch_schedule_pool" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.move_jobs.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule_pool.arn
}
