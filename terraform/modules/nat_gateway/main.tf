resource "aws_eip" "this" {
  domain = "vpc"
  tags = {
    Name        = "${var.env}-nat-eip"
    Component   = "nat-gateway"
    Description = "EIP for NAT Gateway in ${var.env}"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = var.subnet_id
  tags = {
    Name      = "${var.env}-nat-gateway"
    Component = "nat-gateway"
  }

  depends_on = [aws_eip.this]
}