resource "aws_route_table_association" "this" {
  for_each = toset(var.subnet_ids)

  subnet_id      = each.value
  route_table_id = var.route_table_id
}