############################################################
# Terraform Backend 및 Provider 선언
############################################################
terraform {
  backend "remote" {
    organization = "hertz-tuning"
    workspaces {
      name = "gcp-prod"
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
  firewall_rules  = data.terraform_remote_state.shared.outputs.firewall_rules

  region           = var.region
  subnet_self_link = data.terraform_remote_state.shared.outputs.nat_b_subnet_self_link
  vpc_self_link    = data.terraform_remote_state.shared.outputs.vpc_self_link

  hc_backend  = data.terraform_remote_state.shared.outputs.hc_backend_self_link
  hc_frontend = data.terraform_remote_state.shared.outputs.hc_frontend_self_link

  # Blue/Green 배포 상태 계산
  blue_is_active  = var.active_deployment == "blue"
  green_is_active = var.active_deployment == "green"

  external_lb_ip = data.terraform_remote_state.shared.outputs.prod_external_lb_ip_address
  external_lb_ip_self_link = data.terraform_remote_state.shared.outputs.prod_external_lb_ip_self_link
  
  # 트래픽 가중치 검증
  total_weight            = var.traffic_weight_blue + var.traffic_weight_green
  normalized_blue_weight  = local.total_weight > 0 ? (var.traffic_weight_blue * 100 / local.total_weight) : 0
  normalized_green_weight = local.total_weight > 0 ? (var.traffic_weight_green * 100 / local.total_weight) : 0
}


############################################################
# 백엔드(Backend) ASG - Blue/Green
############################################################

# Blue
module "backend_internal_asg_blue" {
  source           = "../../modules/mig-asg"
  name             = "${var.env}-backend-blue-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-medium"
  
  # 동적 인스턴스 수 설정
  desired    = var.blue_instance_count.desired
  min        = var.blue_instance_count.min
  max        = var.blue_instance_count.max
  cpu_target = 0.8

  startup_tpl = join("\n", [
    # 기존 템플릿 파일 호출
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    # Docker 정리 및 실행 스크립트
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

# Green
module "backend_internal_asg_green" {
  source           = "../../modules/mig-asg"
  name             = "${var.env}-backend-green-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-medium"
  
  # 동적 인스턴스 수 설정
  desired    = var.green_instance_count.desired
  min        = var.green_instance_count.min
  max        = var.green_instance_count.max
  cpu_target = 0.8

  startup_tpl = join("\n", [
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

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
# 백엔드 Internal Load Balancer (8080)
############################################################

resource "google_compute_subnetwork" "ilb_proxy_subnet" {
  name          = "${var.vpc_name}-ilb-proxy-subnet"
  ip_cidr_range = var.proxy_subnet_cidr 
  region        = var.region
  network       = local.vpc_self_link

  purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
  role    = "ACTIVE"
}

module "internal_lb" {
  source                 = "../../modules/internal-http-lb"
  region                 = var.region
  subnet_self_link       = local.subnet_self_link
  vpc_self_link          = data.terraform_remote_state.shared.outputs.vpc_self_link
  proxy_subnet_self_link = google_compute_subnetwork.ilb_proxy_subnet.self_link

  backend_name_prefix   = "backend-internal-lb"
  backends = [
    {
      instance_group  = module.backend_internal_asg_blue.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    },
    {
      instance_group  = module.backend_internal_asg_green.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
  backend_hc_port     = 8080
  backend_timeout_sec = 30
  health_check_path   = "/health"
  port                = "8080"
  ip_prefix_length    = 28
}


############################################################
# 프론트엔드(Frontend) ASG - Blue/Green
############################################################

# Blue
module "frontend_asg_blue" {
  source           = "../../modules/mig-asg"
  name             = "${var.env}-frontend-blue-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 20
  machine_type     = "e2-small"
  
  # 동적 인스턴스 수 설정
  desired    = var.blue_instance_count.desired
  min        = var.blue_instance_count.min
  max        = var.blue_instance_count.max
  cpu_target = 0.8

  startup_tpl = join("\n", [
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    <<-EOF
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name app --restart always -p 3000:3000 "\$IMAGE"
    EOF
  ])
  
  port_http    = 80
  health_check = local.hc_frontend
  tags         = ["frontend", "allow-ssh-http", "allow-vpn-ssh"]
}

# Green
module "frontend_asg_green" {
  source           = "../../modules/mig-asg"
  name             = "${var.env}-frontend-green-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 20
  machine_type     = "e2-small"
  
  # 동적 인스턴스 수 설정
  desired    = var.green_instance_count.desired
  min        = var.green_instance_count.min
  max        = var.green_instance_count.max
  cpu_target = 0.8

  startup_tpl = join("\n", [
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    <<-EOF
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name app --restart always -p 3000:3000 "\$IMAGE"
    EOF
  ])
  
  port_http    = 80
  health_check = local.hc_frontend
  tags         = ["frontend", "allow-ssh-http", "allow-vpn-ssh"]
}


############################################################
# External Backend/Frontend Target Group 생성 (HTTP LB 용)
############################################################
module "backend_tg" {
  source       = "../../modules/target-group"
  name         = "${var.env}-backend-tg"
  health_check = local.hc_backend
  backends = [
    {
      instance_group  = module.backend_internal_asg_blue.instance_group
      weight          = local.normalized_blue_weight
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    },
    {
      instance_group  = module.backend_internal_asg_green.instance_group
      weight          = local.normalized_green_weight
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
}

module "frontend_tg" {
  source       = "../../modules/target-group"
  name         = "${var.env}-frontend-tg"
  health_check = local.hc_frontend
  backends = [
    {
      instance_group  = module.frontend_asg_blue.instance_group
      weight          = local.normalized_blue_weight
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    },
    {
      instance_group  = module.frontend_asg_green.instance_group
      weight          = local.normalized_green_weight
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
  name             = "${var.env}-external-lb-b"
  domains          = [var.domain_frontend]
  backend_service  = module.backend_tg.backend_service_self_link
  frontend_service = module.frontend_tg.backend_service_self_link
   lb_ip = {
    address     = local.external_lb_ip
    self_link   = local.external_lb_ip_self_link
  }
}


resource "google_compute_firewall" "allow_internal_hc" {
  name    = "${var.vpc_name}-allow-internal-hc"
  network = data.terraform_remote_state.shared.outputs.vpc_self_link

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags  = ["backend-hc"]
  description  = "Allow GCP Internal LB health checks (TCP:8080) to backend VMs"
}

resource "google_compute_firewall" "allow_ilb_proxy_to_backend" {
  name    = "${var.vpc_name}-allow-ilb-proxy-to-backend"
  network = data.terraform_remote_state.shared.outputs.vpc_self_link

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [ var.proxy_subnet_cidr ]

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  target_tags  = ["backend"]
  description  = "Allow Internal LB proxy (subnet ${var.proxy_subnet_cidr}) to reach backend VMs on TCP/8080"
}
