# IAM roles for AutoScaler

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

resource "aws_iam_role" "auto_scaler" {
  name               = "AutoScaler2"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.auto_scaler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ec2_access" {
  role       = aws_iam_role.auto_scaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.auto_scaler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# Policy to read from SSM parameter gh-secret
data "aws_iam_policy_document" "gh_secret_ssm_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter"
    ]
    resources = ["arn:aws:ssm:eu-west-1:035663780217:parameter/gh-secret"]
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "ReadSSMParameter"
  description = "Policy to read SSM gh-secret"
  policy      = data.aws_iam_policy_document.gh_secret_ssm_policy.json
}

resource "aws_iam_role_policy_attachment" "read_ssm" {
  role       = aws_iam_role.auto_scaler.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

# Policy to allow reading/writing to SQS queue
data "aws_iam_policy_document" "sqs_send_message_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [var.sqs_arn]
  }
}

resource "aws_iam_policy" "sqs_send_policy" {
  name        = "SQSSendMessagePolicy2"
  description = "Policy to send SQS message"
  policy      = data.aws_iam_policy_document.sqs_send_message_policy.json
}

resource "aws_iam_role_policy_attachment" "send_sqs" {
  role       = aws_iam_role.auto_scaler.name
  policy_arn = aws_iam_policy.sqs_send_policy.arn
}