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

resource "aws_iam_role" "stop_runner" {
  name               = "StopRunner"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.stop_runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution_role" {
  role       = aws_iam_role.stop_runner.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy to allow for deleting EC2 instances
data "aws_iam_policy_document" "ec2_delete_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:TerminateInstances",
      "ec2:CancelSpotInstanceRequests"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ec2_delete_policy" {
  name        = "DeleteEC2Instance"
  description = "Policy to delete EC2 instances"
  policy      = data.aws_iam_policy_document.ec2_delete_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_delete_policy" {
  role       = aws_iam_role.stop_runner.name
  policy_arn = aws_iam_policy.ec2_delete_policy.arn
}