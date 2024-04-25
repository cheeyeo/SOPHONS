# IAM role for CreateRunner

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

resource "aws_iam_role" "create_runner" {
  name               = "CreateRunner2"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.create_runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.create_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_queue" {
  role       = aws_iam_role.create_runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# Policy to run CreateFleet
data "aws_iam_policy_document" "create_fleet_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "create_fleet_policy" {
  name        = "CreateFleetPolicy"
  description = "Run CreateFleet from SSM"
  policy      = data.aws_iam_policy_document.create_fleet_policy.json
}

resource "aws_iam_role_policy_attachment" "create_fleet" {
  role       = aws_iam_role.create_runner.name
  policy_arn = aws_iam_policy.create_fleet_policy.arn
}

data "aws_iam_policy_document" "allow_launch_template" {
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [aws_iam_role.self_hosted_runner.arn]
  }
}

resource "aws_iam_policy" "allow_launch_template" {
  name        = "AllowLaunchTemplateEC2InstanceRole"
  description = "Allow SSM to assume EC2 Instance role"
  policy      = data.aws_iam_policy_document.allow_launch_template.json
}

resource "aws_iam_role_policy_attachment" "allow_launch_template" {
  role       = aws_iam_role.create_runner.name
  policy_arn = aws_iam_policy.allow_launch_template.arn
}

# Self-hosted runner EC2 Instance Role
data "aws_iam_policy_document" "AWSEC2TrustPolicy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "self_hosted_runner" {
  name               = var.self_hosted_ec2_instance_role
  assume_role_policy = data.aws_iam_policy_document.AWSEC2TrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "s3_read" {
  role       = aws_iam_role.self_hosted_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_full_access" {
  role       = aws_iam_role.self_hosted_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.self_hosted_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "self_hosted_runner" {
  name = var.self_hosted_ec2_instance_role
  role = aws_iam_role.self_hosted_runner.name
}