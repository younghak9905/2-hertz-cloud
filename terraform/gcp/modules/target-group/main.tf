############################################################
# Target Group(Backend Service) – GCP HTTP(S) LB 전용
############################################################
resource "google_compute_backend_service" "this" {
  description   = var.description
  name          = var.name
  protocol      = var.protocol          # HTTP | HTTPS | HTTP2 | GRPC
  port_name     = var.port_name         # "http" 기본
  timeout_sec   = var.timeout_sec
  health_checks = [var.health_check]    # self_link
  session_affinity          = var.session_affinity
  affinity_cookie_ttl_sec = var.session_affinity == "GENERATED_COOKIE" ? var.affinity_cookie_ttl_sec : null

dynamic "backend" {
  for_each = var.backends
  content {
    group            = backend.value.instance_group
    balancing_mode   = lookup(backend.value, "balancing_mode", "UTILIZATION")
    capacity_scaler  = lookup(backend.value, "capacity_scaler", 1.0)  # 0.0–1.0
  }
}

  connection_draining_timeout_sec = var.connection_draining_sec
  log_config {
    enable      = var.log_enable
    sample_rate = var.log_sample_rate
  }
}
