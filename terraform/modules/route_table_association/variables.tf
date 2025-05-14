variable "subnet_ids" {
  description = "List of subnet IDs to associate"
  type        = list(string)
}

variable "route_table_id" {
  description = "Route table ID to associate with subnets"
  type        = string
}