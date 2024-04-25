variable "sqs_arn" {
  description = "ARN of sqs queue to send webhook events to"
}

variable "sqs_url" {
  description = "URL of SQS queue to send webhook events to"
}

variable "github_secret_name" {
  description = "Name of SSM parameter GITHUB_SECRET"
}