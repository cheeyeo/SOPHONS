variable "template_name" {
  description = "Name of template"
  type        = string
  default     = "SPOT_INSTANCE_TEMPLATE_V2"
}

variable "private_subnet_id" {
  description = "Private subnet id"
  type        = string
}

variable "security_group_id" {
  description = "ID of security group that allows SSM agent access"
  type        = string
}

variable "self_hosted_ec2_instance_name" {
  description = "Name of EC2 Instance role"
  type        = string
}