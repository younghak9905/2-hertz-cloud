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
  firewall_rules  = data.terraform_remote_state.shared.outputs.firewall_rules

  region           = var.region
  subnet_self_link = data.terraform_remote_state.shared.outputs.nat_a_subnet_self_link
  vpc_self_link    = data.terraform_remote_state.shared.outputs.vpc_self_link

  # 헬스체크
  hc_backend  = data.terraform_remote_state.shared.outputs.hc_backend_self_link
  hc_frontend = data.terraform_remote_state.shared.outputs.hc_frontend_self_link

  # Blue/Green 배포 상태 계산
  blue_is_active  = var.active_deployment == "blue"
  green_is_active = var.active_deployment == "green"

  # 트래픽 가중치 검증
  total_weight            = var.traffic_weight_blue + var.traffic_weight_green
  normalized_blue_weight  = local.total_weight > 0 ? (var.traffic_weight_blue * 100 / local.total_weight) : 0
  normalized_green_weight = local.total_weight > 0 ? (var.traffic_weight_green * 100 / local.total_weight) : 0
}

############################################################
# 백엔드(Backend) ASG - 단일 인스턴스용 Unmanaged IG
############################################################

# 1) Backend VM 생성
resource "google_compute_instance" "backend_vm" {
  name         = "${var.env}-backend-vm"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"
  tags         = ["backend", "backend-hc", "allow-vpn-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = local.vpc_self_link
    subnetwork = local.subnet_self_link
  }

  metadata_startup_script = join("\n", [
    # 1) 기존 템플릿 파일 호출
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = var.use_ecr
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
    }),

    # 2) Docker 정리 및 실행 스크립트
    <<-EOF
      docker rm -f app 2>/dev/null || true
      docker pull "\$IMAGE"
      docker run -d --name app --restart always -p 8080:8080 "\$IMAGE"
    EOF
  ])
}

# 2) Unmanaged Instance Group으로 Backend VM 묶기
resource "google_compute_instance_group" "backend_ig" {
  name    = "${var.env}-be-ig-a"
  zone    = "${var.region}-a"
  network = local.vpc_self_link

  instances = [
    google_compute_instance.backend_vm.self_link
  ]
}

############################################################
# 프론트엔드(Frontend) ASG - 단일 인스턴스용 Unmanaged IG
############################################################

# 1) Frontend VM 생성
resource "google_compute_instance" "frontend_vm" {
  name         = "${var.env}-frontend-vm"
  machine_type = "e2-small"
  zone         = "${var.region}-a"
  tags         = ["frontend", "allow-ssh-http", "allow-vpn-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = local.vpc_self_link
    subnetwork = local.subnet_self_link
    access_config {}  # 외부 IP 필요 시 연결
  }

  metadata_startup_script = join("\n", [
    templatefile("${path.module}/scripts/vm-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      docker_image          = var.docker_image_front_blue
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
}

# 2) Unmanaged Instance Group으로 Frontend VM 묶기
resource "google_compute_instance_group" "frontend_ig" {
  name    = "${var.env}-fe-ig-a"
  zone    = "${var.region}-a"
  network = local.vpc_self_link

  instances = [
    google_compute_instance.frontend_vm.self_link
  ]
}

############################################################
# External Backend/Frontend Target Group 생성 (HTTP LB 용)
############################################################

module "backend_tg" {
  source       = "../../modules/target-group"
  name         = "${var.env}-be-tg"
  health_check = local.hc_backend
  backends = [
    {
      instance_group  = google_compute_instance_group.backend_ig.self_link
      weight          = local.normalized_blue_weight
      balancing_mode  = "UTILIZATION"
      capacity_scaler = 1.0
    }
  ]
}

module "frontend_tg" {
  source       = "../../modules/target-group"
  name         = "${var.env}-fe-tg"
  health_check = local.hc_frontend
  backends = [
    {
      instance_group  = google_compute_instance_group.frontend_ig.self_link
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
  name             = "${var.env}-lb-external"
  domains          = [var.domain_frontend]
  backend_service  = module.backend_tg.backend_service_self_link
  frontend_service = module.frontend_tg.backend_service_self_link
}

############################################################
# 공통 방화벽(Firewall) 규칙
############################################################

resource "google_compute_firewall" "dev_firewalls" {
  for_each = { for rule in local.firewall_rules : rule.name => rule }

  name    = "${var.vpc_name}-${each.key}"
  network = local.vpc_self_link

  direction     = each.value.direction
  priority      = each.value.priority
  description   = each.value.description
  source_ranges = lookup(each.value, "source_ranges", [])
  source_tags   = lookup(each.value, "source_tags", [])
  target_tags   = lookup(each.value, "target_tags", [])
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
      description   = "Allow frontend to access backend"
      source_tags   = ["frontend"]
      target_tags   = ["backend"]
      protocol      = "tcp"
      ports         = ["8080"]
    },
    {
      name         = "${var.vpc_name}-fw-backend-to-mysql"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access MySQL"
      source_tags  = ["backend"]
      target_tags  = ["mysql"]
      protocol     = "tcp"
      ports        = ["3306"]
    },
    {
      name         = "${var.vpc_name}-fw-backend-to-redis"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access Redis"
      source_tags  = ["backend", "websocket"]
      target_tags  = ["redis"]
      protocol     = "tcp"
      ports        = ["6379"]
    }
  ]
}
