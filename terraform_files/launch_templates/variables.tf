variable "runner_templates" {
  type = list(
    object({
      template_name                   = string
      ami_id                          = string
      instance_type                   = string
      private_subnet_id               = string
      security_group_id               = string
      ec2_instance_role               = string
      instance_market_type            = string
      instance_interruption_behaviour = string
      instance_max_price              = string
      instance_spot_type              = string
      ebs_device_name                 = optional(string)
      ebs_volume_type                 = optional(string)
      ebs_volume_size                 = optional(number)
      ebs_delete_on_termination       = optional(bool)
      ebs_iops                        = optional(number)
      ebs_throughput                  = optional(number)
    })
  )

  default = [{
    ami_id                          = "ami-0d70174b8586f49a4"
    ec2_instance_role               = "GHSelfHostedRunnerEC2"
    instance_type                   = "c5d.9xlarge"
    private_subnet_id               = "value"
    security_group_id               = "value"
    template_name                   = "gh_runner_template"
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
  }]
}