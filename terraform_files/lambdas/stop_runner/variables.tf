variable "enable_stop_runner" {
  description = "Whether to enable / disable Lambda scheduler. Disable will stop lambda from running"
  default     = true
}

variable "github_token_name" {
  description = "Name of github token used in SSM parameters"
}