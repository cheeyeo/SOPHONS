output "private_subnet_id" {
  value = module.vpc.private_subnets[0]
}

output "security_group_id" {
  value = aws_security_group.allow_tls.id
}