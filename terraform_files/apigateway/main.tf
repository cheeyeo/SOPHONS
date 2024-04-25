# Creates the api gateway which is used as the github webhook

data "aws_iam_policy_document" "AWSApiTrustPolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webhook_auth" {
  name               = "WebhookInvokeAuthFunctionRole2"
  assume_role_policy = data.aws_iam_policy_document.AWSApiTrustPolicy.json
}

resource "aws_iam_role" "integration_auth" {
  name               = "WebhookInvokeIntegrationFunctionRole"
  assume_role_policy = data.aws_iam_policy_document.AWSApiTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "api_gateway_push_logs" {
  role       = aws_iam_role.webhook_auth.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role_policy_attachment" "api_gateway_integration_push_logs" {
  role       = aws_iam_role.integration_auth.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Policy to invoke lambda auth function
data "aws_iam_policy_document" "invoke_auth_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [var.authorizer_arn]
  }
}

data "aws_iam_policy_document" "invoke_integration_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [var.integration_arn]
  }
}

resource "aws_iam_policy" "invoke_auth_lambda_policy" {
  name        = "InvokeAuthLambda2"
  description = "Policy to allow apigateway to invoke auth lambda"
  policy      = data.aws_iam_policy_document.invoke_auth_lambda.json
}

resource "aws_iam_policy" "invoke_integration_lambda_policy" {
  name        = "InvokeIntegrationLambda"
  description = "Policy to allow apigateway to invoke integration lambda"
  policy      = data.aws_iam_policy_document.invoke_integration_lambda.json
}

resource "aws_iam_role_policy_attachment" "invoke_auth_lambda" {
  role       = aws_iam_role.webhook_auth.name
  policy_arn = aws_iam_policy.invoke_auth_lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "invoke_integration_lambda" {
  role       = aws_iam_role.integration_auth.name
  policy_arn = aws_iam_policy.invoke_integration_lambda_policy.arn
}


resource "aws_apigatewayv2_api" "github_webhook" {
  name          = "Github Webhook API2"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "auto_scaler" {
  api_id                 = aws_apigatewayv2_api.github_webhook.id
  integration_type       = "AWS_PROXY"
  connection_type        = "INTERNET"
  integration_method     = "POST"
  integration_uri        = var.integration_invoke_arn
  timeout_milliseconds   = 30000
  credentials_arn        = aws_iam_role.integration_auth.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "example" {
  api_id             = aws_apigatewayv2_api.github_webhook.id
  route_key          = "POST /webhook"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.auth_lambda.id
  target             = "integrations/${aws_apigatewayv2_integration.auto_scaler.id}"
}

# Add stage
resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.github_webhook.id
  name   = "dev"

  auto_deploy = true
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.github_webhook.id
  name   = "$default"

  auto_deploy = true
}

# Add lambda authorizer
resource "aws_apigatewayv2_authorizer" "auth_lambda" {
  api_id                            = aws_apigatewayv2_api.github_webhook.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = var.authorizer_invoke_arn
  name                              = "AuthLambda"
  identity_sources                  = ["$request.header.X-Hub-Signature"]
  authorizer_credentials_arn        = aws_iam_role.webhook_auth.arn
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

