variable "enable_pool_scheduler" {
  description = "To turn on/off the event rule scheduler for PoolJobs"
  default     = true
}

variable "source_queue_arn" {
  description = "Source Queue ARN to move messages from. Normally DQL arn"
}

variable "destination_queue_arn" {
  description = "Destination Queue ARN to move messages to."
}