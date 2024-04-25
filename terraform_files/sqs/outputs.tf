output "queue_arn" {
  value = aws_sqs_queue.github_webhook.arn
}

output "queue_url" {
  value = aws_sqs_queue.github_webhook.url
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}