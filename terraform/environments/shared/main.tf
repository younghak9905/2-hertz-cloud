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
  subnet_id = module.subnet.public_subnet_ids[0]
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

 user_data       = templatefile("${path.module}/scripts/openvpn-init.sh.tpl", {
    admin_password = var.openvpn_admin_password
  })
  
}

module "ec2" {
  source         = "../../modules/ec2"
  name           = "default"
  env            = var.env
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.subnet.nat_subnet_ids[0]  # nat 서브넷 중 하나 선택
  vpn_client_cidr_blocks = [module.subnet.public_subnet_cidrs[0]] 
  ami_id         = "ami-05377cf8cfef186c2"             # amazon linux 2
  instance_type  = "t3.medium"                          # 프리 티어 사용
  key_name       = var.key_name
 
 user_data = templatefile("${path.module}/scripts/dynamic-combine-init.sh.tpl", {
 base_script = templatefile("${path.module}/scripts/ec2-init.sh.tpl", {
    REGION = var.region,
    DOCKER_COMPOSE_VERSION = "2.29.2"
    # 비어있는 맵이라도 제공
  }),
  scripts = {
     /* 추가 스크립트들...
    "nextjs" = templatefile("${path.module}/scripts/nextjs-init.sh.tpl", {
      ecr_repo_url = module.ecr_nextjs.repository_url
      ecr_repo_name = module.ecr_nextjs.repository_name
      */
  }
})

  # 필요하다면 인그레스 규칙을 추가적으로 지정
  /*ingress_rules = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Test app port"
    },
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ["10.0.1.0/24"]
      description = "MySQL from VPN"
    }
    # 필요 시 추가 가능
  ]*/
  
}


# IAM Role and Instance Profile for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.env}-ec2-role" # e.g., shared-ec2-role
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags ={
    Name        = "${var.env}-ec2-role"
    Environment = var.env
    Component   = "ec2"
  }
}

resource "aws_iam_policy" "ebs_management_policy" {
  name        = "${var.env}-ebs-management-policy"
  description = "Policy for EBS volume management (describe, attach, detach)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeStatus",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateSnapshot", // Added for potential backup needs
          "ec2:DeleteSnapshot", // Added for potential cleanup needs
          "ec2:CreateTags"      // To tag volumes/snapshots created by CSI driver
        ]
        Effect   = "Allow"
        Resource = "*" // Consider restricting if specific volume/snapshot ARNs are known/preferred
      }
    ]
  })

  tags = {
    Name        = "${var.env}-ebs-management-policy"
    Environment = var.env
    Component   = "ebs-management"
  }
}

resource "aws_iam_policy" "ecr_read_policy" {
  name        = "${var.env}-ecr-read-policy"
  description = "Policy for read-only access to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories", // Added for listing/discovery
          "ecr:ListImages"
        ]
        Effect   = "Allow"
        Resource = "*" // Consider restricting to specific ECR repository ARNs
      }
    ]
  })

  tags = {
    Name        = "${var.env}-ecr-read-policy"
    Environment = var.env
    Component   = "ecr-read"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_role_ebs_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ebs_management_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_role_ecr_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_read_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.env}-ec2-instance-profile" # e.g., shared-ec2-instance-profile
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "${var.env}-ec2-instance-profile"
    Environment = var.env
    Component   = "ec2"
  }
}