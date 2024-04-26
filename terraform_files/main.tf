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
  source = "./launch_templates"
  runner_templates = [
    {
      template_name                   = "template_cpu"
      ami_id                          = "ami-0d70174b8586f49a4"
      instance_type                   = "c5d.9xlarge"
      private_subnet_id               = module.vpc_runner.private_subnet_id
      security_group_id               = module.vpc_runner.security_group_id
      ec2_instance_role               = "GHSelfHostedRunnerEC2"
      instance_market_type            = "spot"
      instance_interruption_behaviour = "terminate"
      instance_max_price              = "0.90"
      instance_spot_type              = "one-time"
      ebs_device_name                 = "/dev/sda1"
      ebs_volume_type                 = "gp3"
      ebs_volume_size                 = 80
      ebs_delete_on_termination       = true
      ebs_iops                        = 3000
      ebs_throughput                  = 125
    },
    {
      template_name                   = "template_gpu"
      ami_id                          = "ami-077e814ede5564e40"
      instance_type                   = "p3.2xlarge"
      private_subnet_id               = module.vpc_runner.private_subnet_id
      security_group_id               = module.vpc_runner.security_group_id
      ec2_instance_role               = "GHSelfHostedRunnerEC2"
      instance_market_type            = "spot"
      instance_interruption_behaviour = "terminate"
      instance_max_price              = "1.20"
      instance_spot_type              = "one-time"
      ebs_device_name                 = "/dev/sda1"
      ebs_volume_type                 = "gp3"
      ebs_volume_size                 = 80
      ebs_delete_on_termination       = true
      ebs_iops                        = 3000
      ebs_throughput                  = 125
    },
  ]

  depends_on = [module.vpc_runner]
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