resource "aws_launch_template" "spot_instance_template" {
  for_each = { for inst in var.runner_templates : inst.template_name => inst }

  name = each.value.template_name

  image_id = each.value.ami_id

  instance_initiated_shutdown_behavior = "terminate"

  block_device_mappings {
    device_name = each.value.ebs_device_name

    ebs {
      volume_type           = each.value.ebs_volume_type
      volume_size           = each.value.ebs_volume_size
      delete_on_termination = each.value.ebs_delete_on_termination
      iops                  = each.value.ebs_iops
      throughput            = each.value.ebs_throughput
    }
  }

  instance_market_options {
    market_type = each.value.instance_market_type

    spot_options {
      instance_interruption_behavior = each.value.instance_interruption_behaviour
      max_price                      = each.value.instance_max_price
      spot_instance_type             = each.value.instance_spot_type
    }
  }

  instance_type = each.value.instance_type

  iam_instance_profile {
    name = each.value.ec2_instance_role
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    subnet_id                   = each.value.private_subnet_id
    security_groups             = [each.value.security_group_id]
  }

  update_default_version = true
  
  user_data = strcontains(each.value.template_name, "gpu") ? null: filebase64("${path.module}/user_data.sh")
}