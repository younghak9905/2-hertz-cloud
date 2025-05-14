output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "eip_id" {
  description = "The ID of the Elastic IP attached to the NAT Gateway"
  value       = aws_eip.this.id
}