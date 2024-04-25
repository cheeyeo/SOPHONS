data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_webhook_authorizer" {
  name               = "GithubWebhookAuthorizer2"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.github_webhook_authorizer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Inline policy to read from SSM parameter gh-secret
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


data "aws_iam_policy_document" "gh_secret_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.gh_secret_name}"]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "ReadGHSecret"
  description = "Policy to read SSM gh-secret"
  policy      = data.aws_iam_policy_document.gh_secret_ssm_policy.json
}

resource "aws_iam_role_policy_attachment" "read_ssm" {
  role       = aws_iam_role.github_webhook_authorizer.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}