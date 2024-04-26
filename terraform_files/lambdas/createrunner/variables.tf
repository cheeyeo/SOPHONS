variable "sqs_arn" {
  description = "ARN of SQS to create a trigger"
}

variable "sqs_url" {
  description = "URL of SQS queue"
}

variable "enable_sqs_trigger" {
  description = "To switch on/off trigger to read from SQS"
  default     = true
}

variable "self_hosted_ec2_instance_role" {
  description = "EC2 Instance role name"
  type        = string
}

variable "github_token_name" {
  description = "SSM name for Github Token"
}

variable "s3_runner_script_url" {
  description = "S3 Url of runner script"
}

variable "enable_scheduler" {
  description = "whether or not to run lambda in a loop"
  default     = true
}

variable "batch_size" {
  description = "Sets the batch size of messages for lambda to process."
  default     = 7
}

variable "maximum_concurrency" {
  description = "Sets the Maximum concurrency value for event source mapping"
  default     = 7
}

variable "reserved_concurrency" {
  description = "Sets the Reserved concurrency value for lambda"
  default     = 7
}