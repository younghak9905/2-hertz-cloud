output "association_ids" {
  description = "List of route table association IDs"
  value       = [for assoc in aws_route_table_association.this : assoc.id]
}