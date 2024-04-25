/* NOTE: The PAT token needs to be created manually with the following permissions:

Token (Classic)

Scopes:

workflow

admin:org
  read:org
  write:org
  manage_runners:org

*/
variable "gh_token" {
  description = "Github Personal Access Token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "gh_webhook_secret" {
  description = "Github Webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}