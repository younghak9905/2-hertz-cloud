resource "google_compute_instance_template" "this" {
  name_prefix  = "${var.name}-tmpl"
  machine_type = var.machine_type
   disk {
    auto_delete  = true
    boot         = true
    source_image = "projects/${var.project_id}/global/images/base-vm-template"
    disk_size_gb = var.disk_size_gb              # 필요시 조정
    type         = "pd-balanced"
  }
  network_interface {
    subnetwork = var.subnet_self_link
  }
  metadata = {
    ssh-keys = "deploy:${var.deploy_ssh_public_key}"
  }
  metadata_startup_script = var.startup_tpl
  tags = var.tags   # 위 방화벽 규칙의 target_tags와 일치해야 함

  
  service_account { scopes = ["https://www.googleapis.com/auth/cloud-platform"] }


  lifecycle {
    create_before_destroy = true
    # 템플릿 ID가 바뀌면 이 IG 리소스를 대체하도록 강제
  }
}

resource "google_compute_region_instance_group_manager" "this" {
  name               = var.name
  region             = var.region
  base_instance_name = var.name
  //target_size        = var.desired

  named_port {
    name = "http"
    port = var.port_http
  }


  version {
    instance_template  = google_compute_instance_template.this.id
  }

  auto_healing_policies {
    health_check      = var.health_check
    initial_delay_sec = 300
  }

   update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action              = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    
    # Dev 환경: 빠른 완전 교체
    max_surge_fixed = 3
    max_unavailable_fixed = 3
    
    # Dev 환경에서는 교체 속도를 빠르게
    replacement_method = var.is_dev_env ? "SUBSTITUTE" : "RECREATE"
  }
}

resource "google_compute_region_autoscaler" "this" {
  name   = "${var.name}-as"
  region = var.region
  target = google_compute_region_instance_group_manager.this.id

  autoscaling_policy {
    min_replicas    = var.min
    max_replicas    = var.max
    cpu_utilization { target = var.cpu_target }
    cooldown_period = 300
    dynamic "scale_in_control" {
      for_each = var.is_dev_env ? [] : [1]
      content {
        max_scaled_in_replicas {
          fixed = 1
        }
        time_window_sec = 300
      }
    }
  }

  
}