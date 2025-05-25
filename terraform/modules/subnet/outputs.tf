output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public_subnet : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private_subnet : subnet.id]
}

output "nat_subnet_ids" {
  value = [for subnet in aws_subnet.nat_subnet : subnet.id]
}

output "public_subnet_cidrs" {
  description = "Public 서브넷의 CIDR 블록 목록"
  value       = var.public_subnet_cidrs
}