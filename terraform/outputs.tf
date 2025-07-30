# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.patient_app_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.patient_app_vpc.cidr_block
}

# Subnet Outputs
output "public_subnet_1_id" {
  description = "ID of public subnet 1"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
  description = "ID of public subnet 2"
  value       = aws_subnet.public_subnet_2.id
}

output "private_subnet_1_id" {
  description = "ID of private subnet 1"
  value       = aws_subnet.private_subnet_1.id
}

output "private_subnet_2_id" {
  description = "ID of private subnet 2"
  value       = aws_subnet.private_subnet_2.id
}

# Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db_sg.id
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.patient_app_alb.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.patient_app_alb.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.patient_app_alb.arn
}

# Application URL
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.patient_app_alb.dns_name}"
}

# Auto Scaling Group Outputs
output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.patient_app_asg.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.patient_app_asg.arn
}

# Key Pair Output
output "key_pair_name" {
  description = "Name of the EC2 Key Pair"
  value       = aws_key_pair.patient_app_key.key_name
}

# NAT Gateway Outputs
output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.patient_app_nat.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat_eip.public_ip
}
