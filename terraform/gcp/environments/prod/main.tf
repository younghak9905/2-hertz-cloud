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
  name    = "${var.env}-router"
  region  = var.region
  network = data.terraform_remote_state.shared.outputs.vpc_self_link
}

# Cloud NAT용 외부 고정 IP
resource "google_compute_address" "nat_ip" {
  name   = "${var.env}-nat-ip"
  region = var.region
}

# Cloud NAT 설정
resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-nat"
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
  nat_subnet_info = data.terraform_remote_state.shared.outputs.nat_b_subnet_info
  region           = var.region
  subnet_self_link = data.terraform_remote_state.shared.outputs.nat_b_subnet_self_link
  vpc_self_link    = data.terraform_remote_state.shared.outputs.vpc_self_link
  private_subnet_self_link = data.terraform_remote_state.shared.outputs.prod_private_subnet_self_link
  hc_backend  = data.terraform_remote_state.shared.outputs.hc_backend_self_link
  hc_frontend = data.terraform_remote_state.shared.outputs.hc_frontend_self_link
  hc_websocket = data.terraform_remote_state.shared.outputs.hc_websocket_self_link

  external_lb_ip = data.terraform_remote_state.shared.outputs.prod_external_lb_ip_address
  external_lb_ip_self_link = data.terraform_remote_state.shared.outputs.prod_external_lb_ip_self_link

  
  ilb_proxy_subnet_self_link = data.terraform_remote_state.shared.outputs.ilb_proxy_subnet_self_link
  mysql_data_disk_self_link = data.terraform_remote_state.shared.outputs.prod_mysql_data_disk_self_link

}


############################################################
# 백엔드(Backend) ASG - Blue/Green
############################################################

# Blue
module "backend_internal_asg_blue" {
  deploy_ssh_public_key = var.deploy_ssh_public_key
  project_id = var.dev_gcp_project_id
  source           = "../../modules/mig-asg"
  name             = "${var.env}-backend-blue-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-medium"
  # 동적 인스턴스 수 설정
  min        = var.blue_instance_count_backend.min
  max        = var.blue_instance_count_backend.max
  cpu_target = 0.8
  is_dev_env  = false  # 완전 교체 배포 활성화


  startup_tpl = join("\n", [
    # 기존 템플릿 파일 호출
      templatefile("${path.module}/scripts/backend-install.sh.tpl", {
      deploy_ssh_public_key = var.deploy_ssh_public_key
      deploy_ssh_private_key= var.ssh_private_key
      docker_image          = var.docker_image_backend_blue
      use_ecr               = "true"
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      container_name        = "tuning-backend"
      container_port        = "8080"
      host_port            = "8080"
      db_host              = google_compute_address.mysql_internal_ip.address
      ssm_path            = "/global/springboot/prod/"
    })


  ])
  
  health_check = local.hc_backend
  tags         = ["backend", "backend-hc", "allow-vpn-ssh", "websocket"]
  port_http    = 8080
}

# Green
module "backend_internal_asg_green" {
  deploy_ssh_public_key = var.deploy_ssh_public_key
  project_id = var.dev_gcp_project_id
  source           = "../../modules/mig-asg"
  name             = "${var.env}-backend-green-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 30
  machine_type     = "e2-medium"
  
  # 동적 인스턴스 수 설정
  min        = var.green_instance_count_backend.min
  max        = var.green_instance_count_backend.max
  cpu_target = 0.8
  is_dev_env  = false  # 완전 교체 배포 활성화

  startup_tpl = join("\n", [
    templatefile("${path.module}/scripts/backend-install.sh.tpl", {
      deploy_ssh_public_key = var.deploy_ssh_public_key
      deploy_ssh_private_key= var.ssh_private_key
      docker_image          = var.docker_image_backend_green
      use_ecr               = "true"
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      container_name        = "tuning-backend"
      container_port        = "8080"
      host_port            = "8080"
      db_host              = google_compute_address.mysql_internal_ip.address
      ssm_path            = "/global/springboot/prod/"
    })

   
  ])
  
  health_check = local.hc_backend
  tags         = ["backend", "backend-hc", "allow-vpn-ssh","websocket"]
  port_http    = 8080
}


############################################################
# 백엔드 Internal Load Balancer (8080)
############################################################


/*
module "internal_lb" {
  source                 = "../../modules/internal-http-lb"
  region                 = var.region
  subnet_self_link       = local.subnet_self_link
  vpc_self_link          = data.terraform_remote_state.shared.outputs.vpc_self_link
  proxy_subnet_self_link = local.ilb_proxy_subnet_self_link
  env              = "prod"
  backend_name_prefix   = "backend-internal-lb"
  backends = [
    {
      instance_group  = module.backend_internal_asg_blue.instance_group
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_blue_backend / 100.0
    },
    {
      instance_group  = module.backend_internal_asg_green.instance_group
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_green_backend / 100.0
    }
  ]
  backend_hc_port     = 8080
  backend_timeout_sec = 30
  health_check_path   = "/api/ping"
  port                = "8080"
  ip_prefix_length    = 28
}*/


############################################################
# 프론트엔드(Frontend) ASG - Blue/Green
############################################################

# Blue
module "frontend_asg_blue" {
  deploy_ssh_public_key = var.deploy_ssh_public_key
  project_id = var.dev_gcp_project_id
  source           = "../../modules/mig-asg"
  name             = "${var.env}-frontend-blue-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 20
  machine_type     = "e2-small"
  
  # 동적 인스턴스 수 설정
  min        = var.blue_instance_count_frontend.min
  max        = var.blue_instance_count_frontend.max
  cpu_target = 0.8
  is_dev_env  = false  # 완전 교체 배포 활성화

  startup_tpl = join("\n", [
       templatefile("${path.module}/scripts/frontend-install.sh.tpl", {
      deploy_ssh_public_key = var.deploy_ssh_public_key
      docker_image          = var.docker_image_front_blue
      use_ecr               = "true"
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      container_name        = "tuning-frontend"
      container_port        = "3000"
      host_port            = "80"
      ssm_path            = "/global/nextjs/prod/"
    })
  ])
  
  port_http    = 80
  health_check = local.hc_frontend
  tags         = ["frontend", "allow-ssh-http", "allow-vpn-ssh"]
}

# Green
module "frontend_asg_green" {

  project_id = var.dev_gcp_project_id
  source           = "../../modules/mig-asg"
  name             = "${var.env}-frontend-green-b"
  region           = var.region
  subnet_self_link = local.subnet_self_link
  disk_size_gb     = 20
  machine_type     = "e2-small"
  
  # 동적 인스턴스 수 설정
  min        = var.green_instance_count_frontend.min
  max        = var.green_instance_count_frontend.max
  cpu_target = 0.8
  is_dev_env  = false  # 완전 교체 배포 활성화

  startup_tpl = join("\n", [
       templatefile("${path.module}/scripts/frontend-install.sh.tpl", {
      deploy_ssh_public_key = var.deploy_ssh_public_key
      docker_image          = var.docker_image_front_green
      use_ecr               = "true"
      aws_region            = var.aws_region
      aws_access_key_id     = var.aws_access_key_id
      aws_secret_access_key = var.aws_secret_access_key
      container_name        = "tuning-frontend"
      container_port        = "3000"
      host_port            = "80"
      ssm_path            = "/global/nextjs/prod/"
    })

   
  ])
  
  port_http    = 80
  health_check = local.hc_frontend
  tags         = ["frontend", "allow-ssh-http", "allow-vpn-ssh"]
}
/*
module "websocket_ig" {
  source           = "../../modules/mig-asg"
  project_id       = var.dev_gcp_project_id
  deploy_ssh_public_key = var.deploy_ssh_public_key

  name             = "${var.env}-ws-ig-b"        # e.g. dev-ws-ig-b
  region           = var.region
  subnet_self_link = local.subnet_self_link

  disk_size_gb     = 20
  machine_type     = "e2-medium"

  # 최소/최대 인스턴스 수 및 CPU 타겟
  min        = 1
  max        = 2
  cpu_target = 0.8
  is_dev_env  = false  # 완전 교체 배포 활성화

  # startup script: WebSocket 서버 실행용 템플릿
  # scripts/websocket-install.sh.tpl 파일을 하나 만들어두고,
  # 아래 변수들을 전달하세요.
 startup_tpl = join("\n", [
    templatefile("${path.module}/scripts/websocket-intstall.sh.tpl", {
      deploy_ssh_public_key  = var.deploy_ssh_public_key
      deploy_ssh_private_key = var.ssh_private_key

      docker_image           = var.docker_image_websocket   # ex) tuning-websocket:latest
      use_ecr                = "true"
      aws_region             = var.aws_region
      aws_access_key_id      = var.aws_access_key_id
      aws_secret_access_key  = var.aws_secret_access_key
      ssm_path               = "/global/websocket/prod/"
      container_name         = "tuning-websocket"
      container_port         = "9092"
      host_port              = "9092"
      # (필요시) 추가 환경변수들…
    })
  ])

  # 앞서 만든 WebSocket 전용 Health Check
  health_check = local.hc_websocket

  tags = [
    "websocket", "allow-vpn-ssh",
  ]

  # 내부적으로 Nginx → Netty 로 가정할 때, 포트 HTTP 모드로 9092 바인딩
  port_http = 9092
}*/


############################################################
# External Backend/Frontend Target Group 생성 (HTTP LB 용)
############################################################
module "backend_tg" {
  source       = "../../modules/target-group"
  description  = "Traffic: blue ${var.traffic_weight_blue_backend}% / green ${var.traffic_weight_green_backend}%"
  name         = "${var.env}-backend-tg"
  health_check = local.hc_backend
  backends = [
    {
      instance_group  = module.backend_internal_asg_blue.instance_group
      # weight          = local.normalized_blue_weight
      # weight          = var.traffic_weight_blue
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_blue_backend / 100.0
    },
    {
      instance_group  = module.backend_internal_asg_green.instance_group
      # weight          = local.normalized_green_weight
      # weight          = var.traffic_weight_green
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_green_backend / 100.0
    }
  ]
}

module "frontend_tg" {
  source       = "../../modules/target-group"
  description  = "Traffic: blue ${var.traffic_weight_blue_frontend}% / green ${var.traffic_weight_green_frontend}%"
  name         = "${var.env}-frontend-tg"
  health_check = local.hc_frontend
  backends = [
    {
      instance_group  = module.frontend_asg_blue.instance_group
      # weight          = local.normalized_blue_weight
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_blue_frontend / 100.0
    },
    {
      instance_group  = module.frontend_asg_green.instance_group
      # weight          = local.normalized_green_weight
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_green_frontend / 100.0
    }
  ]
}

module "websocket_tg" {
  source       = "../../modules/target-group"
  name         = "${var.env}-ws-tg"
  description  = "WebSocket Target Group"
  protocol = "HTTP"
  health_check = local.hc_backend
  port_name = "ws"
   backends = [
    {
      instance_group  = module.backend_internal_asg_blue.instance_group
      # weight          = local.normalized_blue_weight
      # weight          = var.traffic_weight_blue
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_blue_backend / 100.0
    },
    {
      instance_group  = module.backend_internal_asg_green.instance_group
      # weight          = local.normalized_green_weight
      # weight          = var.traffic_weight_green
      balancing_mode  = "UTILIZATION"
      # capacity_scaler = 1.0
      capacity_scaler = var.traffic_weight_green_backend / 100.0
    }
  ]
  timeout_sec             = 86400
  session_affinity        = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 0
  
}

############################################################
# 외부 HTTPS LB + URL Map (프론트엔드 기본, /api/* 백엔드)
############################################################
module "external_lb" {
  source           = "../../modules/external-https-lb"
  name             = "${var.env}-lb-external"
  env = var.env
  domains          = [var.domain_frontend]
  backend_service  = module.backend_tg.backend_service_self_link
  frontend_service = module.frontend_tg.backend_service_self_link
  websocket_service = module.websocket_tg.backend_service_self_link
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


resource "google_compute_address" "mysql_internal_ip" {
  name         = "${var.env}-mysql-internal-ip"
  address_type = "INTERNAL"
  subnetwork   = local.private_subnet_self_link  # 원하는 서브넷
  region       = var.region
  address      = var.mysql_internal_ip 
}


resource "google_compute_instance" "mysql_vm" {
  name         = "${var.env}-mysql-vm"
  machine_type = "e2-small"
  zone         = "${var.region}-b"
  tags         = ["mysql", "redis", "allow-vpn-ssh"]

  boot_disk {

    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30
      type  = "pd-balanced"
    }
  }

  # ──────────────────────────────────────────────────────────────────
  #  이 부분을 추가: Persistent Disk(mysql_data) 연결
  # ──────────────────────────────────────────────────────────────────
  attached_disk {
    source      = local.mysql_data_disk_self_link
    device_name = "mysql-data"    # 내부적으로 /dev/disk/by-id/google-mysql-data 로 참조됨
    mode        = "READ_WRITE"
          # 인스턴스 삭제 시에도 디스크는 남아 있게 설정
  }

  network_interface {
    network    = local.vpc_self_link
    subnetwork = local.private_subnet_self_link
    network_ip = google_compute_address.mysql_internal_ip.address
    # 외부 접근 필요 없으면 access_config 생략
  }

  metadata_startup_script =join("\n", [
    templatefile("${path.module}/scripts/db-install.sh.tpl", {
      deploy_ssh_public_key = var.ssh_private_key
      rootpasswd            = var.mysql_root_password,
      db_name               = var.mysql_database_name,
      user_name             = var.mysql_user_name
      redis_password        = var.redis_password
    })
    
  ])
}


resource "google_compute_firewall" "prod_firewalls" {
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
 
  # 2) 직접 정의한 추가 방화벽 규칙
  firewall_rules = [
    {
      name          = "${var.env}-fw-frontend-to-backend"
      direction     = "INGRESS"
      priority      = 1000
      description   = "Allow frontend to access backend"
      source_tags   = ["frontend"]
      target_tags   = ["backend"]
      protocol      = "tcp"
      ports         = ["8080"]
    },
    {
      name         = "${var.env}-fw-backend-to-mysql"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access MySQL"
      source_tags  = ["backend"]
      target_tags  = ["mysql"]
      protocol     = "tcp"
      ports        = ["3306"]
    },
    # {
    #   name         = "${var.env}-fw-backend-to-backend"
    #   direction    = "INGRESS"
    #   priority     = 1000
    #   description  = "Allow backend to access Redis"
    #   source_tags  = ["backend"]
    #   target_tags  = ["websocket"]
    #   protocol     = "tcp"
    #   ports        = ["9093"]
    # },
    {
      name         = "${var.env}-fw-befe-to-websocket"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access websocket"
      source_tags  = ["backend","frontend"]
      target_tags  = ["websocket"]
      protocol     = "tcp"
      ports        = ["9100"]
    },
    {
      name         = "${var.env}-fw-backend-to-redis"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow backend to access Redis"
      source_tags  = ["backend", "websocket"]
      target_tags  = ["redis"]
      protocol     = "tcp"
      ports        = ["6379"]
    },

    {
      name        = "${var.env}-fw-kafka-to-kafka"
      direction   = "INGRESS"
      priority    = 1000
      description = "Allow Kafka access from  on ports 9092-9094"
      # 허용할 소스 IP (싱글 IP라면 /32)
      source_ranges = var.kafka_source_ranges
      # 태그가 kafka 인 인스턴스에만 적용
      target_tags   = ["backend","frontend"]
      protocol      = "tcp"    
      ports    = ["9092-9094"]
    },
    {
      name         = "${var.env}-fw-kafka-to-redis"
      direction    = "INGRESS"
      priority     = 1000
      description  = "Allow kafka to access redis"
      source_tags  = ["kafka"]
      target_tags  = ["redis"]
      protocol     = "tcp"
      ports        = ["6379"]
    },

    {
      name          = "${var.env}-fw-to-websocket"
      direction     = "INGRESS"
      priority      = 1000
      description   = "Allow GCP Health Checks (130.211.0.0/22, 35.191.0.0/16) to websocket on TCP:9100"
      source_ranges = [
        "130.211.0.0/22",
        "35.191.0.0/16",
      ]
      target_tags   = ["websocket","backend"]
      protocol      = "tcp"
      ports         = ["9100"]
    }
   
   
  ]

}