terraform {
  required_version = ">= 1.2.7, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }
  }

  backend "s3" {
    bucket  = "github-tf-state-2024"
    key     = "state/terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "ssm_parameters" {
  source            = "./ssm_parameters"
  gh_token          = var.gh_token
  gh_webhook_secret = var.gh_webhook_secret
}

module "vpc_runner" {
  source = "./vpc"
}

module "launch_template" {
  source                        = "./launch_templates"
  private_subnet_id             = module.vpc_runner.private_subnet_id
  security_group_id             = module.vpc_runner.security_group_id
  template_name                 = "SPOT_INSTANCE_TEMPLATE_V2"
  self_hosted_ec2_instance_name = "GHSelfHostedRunnerEC2"
}

module "ssm_runcommand" {
  source                = "./ssm_runcommand"
  runner_script_s3_name = "self-runner-script"
}

module "sqs" {
  source = "./sqs"
}

module "webhook_authorizer" {
  source         = "./lambdas/gh_authorizer"
  gh_secret_name = "/self-hosted-runner/github/gh-secret"
}

module "auto_scaler" {
  source             = "./lambdas/autoscaler"
  sqs_arn            = module.sqs.queue_arn
  sqs_url            = module.sqs.queue_url
  github_secret_name = "/self-hosted-runner/github/gh-secret"
}

module "create_runner" {
  source                        = "./lambdas/createrunner"
  sqs_arn                       = module.sqs.queue_arn
  sqs_url                       = module.sqs.queue_url
  launch_template_name          = "SPOT_INSTANCE_TEMPLATE_V2"
  github_token_name             = "/self-hosted-runner/github/gh-token"
  self_hosted_ec2_instance_role = "GHSelfHostedRunnerEC2"
  s3_runner_script_url          = module.ssm_runcommand.s3_script_url
}

module "move_jobs" {
  source                = "./lambdas/move_jobs"
  source_queue_arn      = module.sqs.dlq_arn
  destination_queue_arn = module.sqs.queue_arn
  enable_pool_scheduler = true
}

module "stop_runner" {
  source             = "./lambdas/stop_runner"
  github_token_name  = "/self-hosted-runner/github/gh-token"
  enable_stop_runner = true
}

module "api_gateway" {
  source                 = "./apigateway"
  authorizer_arn         = module.webhook_authorizer.lambda_arn
  authorizer_invoke_arn  = module.webhook_authorizer.invoke_arn
  integration_arn        = module.auto_scaler.lambda_arn
  integration_invoke_arn = module.auto_scaler.invoke_arn
}

output "apigateway_url" {
  value = module.api_gateway.apigateway_url
}

output "apigateway_default_url" {
  value = module.api_gateway.apigateway_url_default
}