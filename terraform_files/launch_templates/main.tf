resource "aws_launch_template" "spot_instance_template" {
  name = var.template_name

  image_id = "ami-0d70174b8586f49a4"

  instance_initiated_shutdown_behavior = "terminate"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 80
      delete_on_termination = true
      iops                  = 3000
      throughput            = 125
    }
  }

  instance_market_options {
    market_type = "spot"

    spot_options {
      instance_interruption_behavior = "terminate"
      max_price                      = "0.90"
      spot_instance_type             = "one-time"
    }
  }

  instance_type = "c5d.9xlarge"

  iam_instance_profile {
    name = var.self_hosted_ec2_instance_name
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    subnet_id                   = var.private_subnet_id
    security_groups             = [var.security_group_id]
  }

  user_data = filebase64("${path.module}/user_data.sh")
}