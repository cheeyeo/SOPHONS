resource "aws_ssm_parameter" "gh-token" {
  name  = "/self-hosted-runner/github/gh-token"
  type  = "SecureString"
  value = var.gh_token

  tags = {
    self-hosted-runner = "github"
  }
}


resource "aws_ssm_parameter" "gh-secret" {
  name  = "/self-hosted-runner/github/gh-secret"
  type  = "SecureString"
  value = var.gh_webhook_secret

  tags = {
    self-hosted-runner = "github"
  }
}