############################################################
# Terraform Backend 및 Provider 선언
############################################################
terraform {
  backend "remote" {
    organization = "hertz-tuning"
    workspaces {
      name = "gcp-develop"
    }
  }
}

# 기존에 생성된 리소스(공유 VPC 등) 상태 조회
data "terraform_remote_state" "shared" {
  backend = "remote"
  config = {
    organization = "hertz-tuning"
    workspaces = {
      name = "gcp-shared"
    }
  }
}

provider "google" {
  credentials = var.dev_gcp_sa_key
  project     = var.dev_gcp_project_id
  region      = var.region
}

############################################################
# 네트워크/라우팅 및 NAT 리소스
############################################################

# Cloud Router 생성
resource "google_compute_router" "router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = data.terraform_remote_state.shared.outputs.vpc_self_link
}

# Cloud NAT용 외부 고정 IP
resource "google_compute_address" "nat_ip" {
  name   = "${var.vpc_name}-nat-ip"
  region = var.region
}

# Cloud NAT 설정
resource "google_compute_router_nat" "nat" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = local.nat_subnet_info
    content {
      name                    = subnetwork.value.self_link
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

locals {
  nat_subnet_info = data.terraform_remote_state.shared.outputs.nat_subnet_info
  firewall_rules = data.terraform_remote_state.shared.outputs.firewall_rules

  region           = var.region
  subnet_self_link = data.terraform_remote_state.shared.outputs.nat_a_subnet_self_link
  vpc_self_link    = data.terraform_remote_state.shared.outputs.vpc_self_link

   # Blue/Green 배포 상태 계산
  blue_is_active  = var.active_deployment == "blue"
  green_is_active = var.active_deployment == "green"

  #헬스체크
  hc_backend = data.terraform_remote_state.shared.outputs.hc_backend_self_link
  hc_frontend = data.terraform_remote_state.shared.outputs.hc_frontend_self_link
  
  # 트래픽 가중치 검증
  total_weight = var.traffic_weight_blue + var.traffic_weight_green
  normalized_blue_weight  = local.total_weight > 0 ? (var.traffic_weight_blue * 100 / local.total_weight) : 0
  normalized_green_weight = local.total_weight > 0 ? (var.traffic_weight_green * 100 / local.total_weight) : 0
}



############################################################
# 백엔드(Backend) ASG - Blue/Green
############################################################

# Blue
# 1) Internal 전용 MIGs (Internal LB용)
# Blue
module "backend_ig" {
  source           = "../../modules/mig-asg"
  name             = var.env+"-be_ig-a"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-medium"
  
  # 동적 인스턴스 수 설정
  desired    = 1
  min        = 1
  max        = 1
  cpu_target = 0.8

  startup_tpl = join("\n", [
    # 1) 기존 템플릿 파일 (base-init.sh.tpl) 호출
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    # 2) 직접 here-doc으로 붙일 Docker 관련 명령
    <<-EOF
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name app --restart always -p 8080:8080 "\$IMAGE"
    EOF
  ])
  
  health_check = local.hc_backend
  tags         = ["backend", "backend-hc", "allow-vpn-ssh"]
  port_http    = 8080
}



############################################################
# 프론트엔드(Frontend) ASG - Blue/Green
############################################################
# Blue
module "frontend_ig" {
  source           = "../../modules/mig-asg"
  name             = var.env+"-fe-ig-a"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-small"
  
  # 동적 인스턴스 수 설정
  desired    = 1
  min        = 1
  max        = 1
  cpu_target = 0.8

    startup_tpl = join("\n", [
    # 1) 기존 템플릿 파일 (base-init.sh.tpl) 호출
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    # 2) 직접 here-doc으로 붙일 Docker 관련 명령
    <<-EOF
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name app --restart always -p 3000:3000 "\$IMAGE"
    EOF
  ])
  
  port_http    = 80
  health_check = local.hc_frontend
  tags         = ["allow-ssh-http", "allow-vpn-ssh"]
}

############################################################
# External Backend/Frontend Target Group 생성 (HTTP LB 용)
############################################################
module "backend_tg" {
  source       = "../../modules/target-group"
  name         = var.env+"-be_tg"
  health_check = local.hc_backend
  backends = [
    {
      instance_group  = module.backend_ig.instance_group
      weight          = local.normalized_blue_weight  # 동적 가중치
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
}

module "frontend_tg" {
  source       = "../../modules/target-group"
  name         = var.env+"-fe_tg"
  health_check = local.hc_frontend
  backends = [
    {
      instance_group  = module.frontend_ig.instance_group
      weight          = 100
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
}


############################################################
# 외부 HTTPS LB + URL Map (프론트엔드 기본, /api/* 백엔드)
############################################################

module "external_lb" {
  source           = "../../modules/external-https-lb"
  name             = var.env+"lb-external"
  domains          = [var.domain_frontend]
  backend_service  = module.backend_tg.backend_service_self_link      # /api/* 경로용
  frontend_service = module.frontend_tg.backend_service_self_link     # 그 외 기본 경로용
}

/*

module "mysql" {
    source                = "../../modules/compute"
    name                  = var.env+"-mysql"
    machine_type          = "e2-small"
    zone                  = "asia-east1-a"
    image                 = "ubuntu-os-cloud/ubuntu-2204-lts"
    disk_size_gb          = 30
    tags                  = ["mysql","allow-vpn-ssh",]
    
    subnetwork            = data.terraform_remote_state.shared.outputs.nat_a_subnet_self_link
    
    # ✅ deploy 계정의 SSH 키는 base-init.sh.tpl에서 사용됨
    deploy_ssh_public_key = var.ssh_private_key
    
    service_account_email  = var.default_sa_email
    service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    extra_startup_script = join("\n", [
    # 1) 기존에 분리해둔 base-init 스크립트
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_green
      use_ecr               = no
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),
    <<-EOF
      # 기존에 실행 중인 "app" 컨테이너 있으면 삭제
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name mysql --restart always -p 3306:3306 "\$IMAGE"
    EOF
    ]
    )
}*/


resource "google_compute_firewall" "dev_firewalls" {
  for_each = { for rule in local.firewall_rules : rule.name => rule }

  name    = "${var.vpc_name}-${each.key}"
  network = local.vpc_self_link

  direction     = each.value.direction
  priority      = each.value.priority
  description   = each.value.description
  source_ranges = each.value.source_ranges
  target_tags   = lookup(each.value, "target_tags", [])
  source_tags   = lookup(each.value, "source_tags", [])
  allow {
    protocol = each.value.protocol
    ports    = lookup(each.value, "ports", [])
  }
}

locals {
  firewall_rules = [
    {
      name          = "${var.vpc_name}-fw-frontend-to-backend"
      direction     = "INGRESS"
      priority      = 1000
      description   = "Allow SSH access"
      source_tags = ["frontend"]
      target_tags  = ["backend"]
      protocol      = "tcp"
      ports         = ["8080"]
    },
    {
      name         = "${var.vpc_name}-fw-backend-to-mysql"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access MySQL"
      source_tags = ["backend"]
      target_tags  = ["mysql"]
      protocol     = "tcp"
      ports        = ["3306"]
    },
    {
      name         = "${var.vpc_name}-fw-backend-to-redis"
      direction    = "INGRESS"
      priority     = 1000
      source_tags  = ["backend", "websocket"]
      target_tags  = ["redis"]
      description  = "Allow backend to access Redis"
      protocol     = "tcp"
      ports        = ["6379"]

    }

  ]
}

