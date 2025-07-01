resource "aws_subnet" "public_subnet" {
  count = length(var.azs)

  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.env}-public-subnet-${var.azs[count.index]}"
    Component = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.azs)

  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name      = "${var.env}-private-subnet-${var.azs[count.index]}"
    Component = "private-subnet"
  }
}

resource "aws_subnet" "nat_subnet" {
  count = length(var.azs)

  vpc_id            = var.vpc_id
  cidr_block        = var.nat_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name      = "${var.env}-nat-subnet-${var.azs[count.index]}"
    Component = "nat-subnet"
  }
}

# resource "aws_subnet" "nat_subnet" {
#   count = 1

#   vpc_id            = var.vpc_id
#   cidr_block        = var.nat_subnet_cidrs[0]
#   availability_zone = var.azs[0]

#   tags = {
#     Name      = "${var.env}-nat-subnet-${var.azs[0]}"
#     Component = "nat-subnet"
#   }
# }