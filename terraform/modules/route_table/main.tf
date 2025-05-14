resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.env}-${var.is_public ? "public" : "private"}-rtb"
    Component = var.is_public ? "public-route-table" : "private-route-table"
  }
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"

  gateway_id       = var.is_public ? var.igw_id : null
  nat_gateway_id   = var.is_public ? null : var.nat_gateway_id

  depends_on = [aws_route_table.this]
}