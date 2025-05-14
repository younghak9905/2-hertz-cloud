module "vpc" {
  source     = "../../modules/vpc"
  env        = var.env
  cidr_block = "10.0.0.0/16"
}

module "subnet" {
  source = "../../modules/subnet"

  env                    = var.env
  vpc_id                 = module.vpc.vpc_id
  azs                    = var.azs
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  nat_subnet_cidrs       = var.nat_subnet_cidrs
}

module "nat_gateway" {
  source    = "../../modules/nat_gateway"
  env       = var.env
  subnet_id = module.subnet.nat_subnet_ids[0]
}

module "public_route_table" {
  source    = "../../modules/route_table"
  env       = var.env
  vpc_id    = module.vpc.vpc_id
  is_public = true
  igw_id    = module.vpc.igw_id
}

module "nat_route_table" {
  source          = "../../modules/route_table"
  env             = var.env
  vpc_id          = module.vpc.vpc_id
  is_public       = false
  nat_gateway_id  = module.nat_gateway.nat_gateway_id
}

module "public_route_table_assoc" {
  source         = "../../modules/route_table_association"
  subnet_ids     = module.subnet.public_subnet_ids
  route_table_id = module.public_route_table.route_table_id
}

module "nat_route_table_assoc" {
  source         = "../../modules/route_table_association"
  subnet_ids     = module.subnet.nat_subnet_ids
  route_table_id = module.nat_route_table.route_table_id
}