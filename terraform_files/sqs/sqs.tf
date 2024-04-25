resource "aws_sqs_queue" "github_webhook" {
  name = "GithubWebhookEvents2"
  # visibility_timeout_seconds = 5400
  visibility_timeout_seconds = 1800
  delay_seconds              = 30
  message_retention_seconds  = 86400
  max_message_size           = 262144
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Dead letter queue
resource "aws_sqs_queue" "dlq" {
  name = "WebHookDLQ"
}

resource "aws_sqs_queue_redrive_allow_policy" "github_webhook_redrive_allow_policy" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.github_webhook.arn]
  })
}

data "aws_caller_identity" "current" {}

# Access Policy - scoped to current user account?
data "aws_iam_policy_document" "sqs_access" {
  statement {
    sid    = "__owner_statement"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
    actions   = ["SQS:*"]
    resources = [resource.aws_sqs_queue.github_webhook.arn]
  }
}

resource "aws_sqs_queue_policy" "default" {
  queue_url = aws_sqs_queue.github_webhook.id
  policy    = data.aws_iam_policy_document.sqs_access.json
}