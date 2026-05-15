output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "intra_subnet_ids" {
  description = "IDs of the intra (isolated) subnets."
  value       = aws_subnet.intra[*].id
}

output "default_security_group_id" {
  description = "ID of the VPC default security group, locked with no rules."
  value       = aws_default_security_group.this.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway, or null when no public subnets exist."
  value       = try(aws_internet_gateway.this[0].id, null)
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = aws_nat_gateway.this[*].id
}

output "flow_log_id" {
  description = "ID of the VPC flow log, or null when flow logs are disabled."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_log_group_name" {
  description = "Name of the flow log CloudWatch log group, or null when flow logs are disabled."
  value       = try(aws_cloudwatch_log_group.flow_log[0].name, null)
}
