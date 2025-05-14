resource "aws_subnet" "public_subnet" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[each.value]
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.env}-public-subnet-${each.key}"
    Component = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[each.value]
  availability_zone = each.key

  tags = {
    Name      = "${var.env}-private-subnet-${each.key}"
    Component = "private-subnet"
  }
}

resource "aws_subnet" "nat_subnet" {
  for_each = { for idx, az in var.azs : az => idx }

  vpc_id            = var.vpc_id
  cidr_block        = var.nat_subnet_cidrs[each.value]
  availability_zone = each.key

  tags = {
    Name      = "${var.env}-nat-subnet-${each.key}"
    Component = "nat-subnet"
  }
}