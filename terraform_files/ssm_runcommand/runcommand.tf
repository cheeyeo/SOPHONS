# Creates S3 bucket to store and run jit_runner.sh script
locals {
  runner_script_path = "${path.module}/../../custom_runners/jit_runner.sh"
}

resource "aws_s3_bucket" "runner_script" {
  bucket = var.runner_script_s3_name

  tags = {
    Name        = "self-hosted-runner"
    Environment = "github"
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.runner_script.id
  key    = "jit_runner.sh"
  source = local.runner_script_path
  etag   = filemd5(local.runner_script_path)
}

# Cloudwatch log group to store runner script logs
resource "aws_cloudwatch_log_group" "runner_logs" {
  name = "/aws/ssm/runner_logs"

  retention_in_days = 30
}

output "s3_script_url" {
  value = "https://${aws_s3_bucket.runner_script.id}.s3.${aws_s3_bucket.runner_script.region}.amazonaws.com/${aws_s3_object.object.key}"
}