### Terraform Cloud 관련
terraform {
  backend "remote" {
    organization = "hertz-tuning"

    workspaces {
      name = "terraform-shared"
    }
  }
}

provider "aws" {
  region = var.region
}

### VPC 관련

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

### ECR

module "ecr_nextjs" {
  source = "../../modules/ecr"
  name   = "tuning-nextjs"
  env    = var.env
}

module "ecr_springboot" {
  source = "../../modules/ecr"
  name   = "tuning-springboot"
  env    = var.env
}

module "ecr_fastapi" {
  source = "../../modules/ecr"
  name   = "tuning-fastapi"
  env    = var.env
}

module "ecr_chromadb" {
  source = "../../modules/ecr"
  name   = "tuning-chromadb"
  env    = var.env
}

### OpenVPN (EC2)
module "ec2-openvpn" {
  source         = "../../modules/ec2-openvpn"
  name           = "openvpn"
  env            = var.env
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.subnet.public_subnet_ids[0]  # public 서브넷 중 하나 선택
  ami_id         = "ami-0ba7b69b8b03f0bf1"             # OpenVPN BYOL AMI ID
  instance_type  = "t2.micro"                          # 프리 티어 사용
  key_name       = var.key_name
}