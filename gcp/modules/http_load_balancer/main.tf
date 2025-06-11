resource "google_compute_health_check" "default" {
  project = var.project_id # To be defined in variables.tf
  name    = "${var.lb_name}-health-check" # To be defined in variables.tf

  http_health_check {
    port_specification = "USE_SERVING_PORT"
    request_path       = var.health_check_path
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

resource "google_compute_backend_service" "default" {
  project = var.project_id # To be defined in variables.tf
  name    = "${var.lb_name}-backend-service" # To be defined in variables.tf

  port_name          = "http" # Assuming WebSocket server listens on HTTP port before LB termination
  protocol           = "HTTPS" # For wss:// termination at the LB
  load_balancing_scheme = "EXTERNAL_MANAGED" # For HTTP(S) Global External Load Balancer
  timeout_sec        = var.backend_timeout_sec # Define in variables.tf, suggest 86400 for WebSockets

  backend {
    group = var.instance_group_self_link # To be defined in variables.tf (e.g., a managed instance group)
    # balancing_mode might be "UTILIZATION" or "RATE" depending on autoscaling setup
  }

  health_checks = [google_compute_health_check.default.id]

  session_affinity = "GENERATED_COOKIE"
  affinity_cookie_ttl_sec = 0 # 0 means session cookie

  # Depending on the application, CDN might be disabled for dynamic WebSocket content
  # enable_cdn = false

  # IAP configuration can be added here if needed
  # iap {
  #   oauth2_client_id     = var.iap_oauth2_client_id
  #   oauth2_client_secret = var.iap_oauth2_client_secret
  # }
}

resource "google_compute_url_map" "default" {
  project = var.project_id # To be defined in variables.tf
  name    = "${var.lb_name}-url-map" # To be defined in variables.tf

  default_service = google_compute_backend_service.default.id

  # Example of path-based routing if needed in the future:
  # host_rule {
  #   hosts        = ["*"]
  #   path_matcher = "allpaths"
  # }
  #
  # path_matcher {
  #   name            = "allpaths"
  #   default_service = google_compute_backend_service.default.id
  #
  #   # Example for specific path if you had other services
  #   # path_rule {
  #   #   paths   = ["/api/*"]
  #   #   service = google_compute_backend_service.api.id
  #   # }
  # }
}

resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id # To be defined in variables.tf
  name    = "${var.lb_name}-managed-ssl-cert" # To be defined in variables.tf

  managed {
    domains = var.managed_ssl_certificate_domains # To be defined in variables.tf, e.g., ["ws.example.com"]
  }
}

resource "google_compute_target_https_proxy" "default" {
  project = var.project_id # To be defined in variables.tf
  name    = "${var.lb_name}-https-proxy" # To be defined in variables.tf

  url_map           = google_compute_url_map.default.id
  ssl_certificates  = [google_compute_managed_ssl_certificate.default.self_link]

  # QUIC protocol can be optionally overridden if specific behavior is needed
  # quic_override = "NONE" # or "ENABLE", "DISABLE"
}

resource "google_compute_global_forwarding_rule" "default" {
  project               = var.project_id # To be defined in variables.tf
  name                  = "${var.lb_name}-forwarding-rule" # To be defined in variables.tf

  target                = google_compute_target_https_proxy.default.id
  port_range            = "443" # Standard port for HTTPS
  load_balancing_scheme = "EXTERNAL_MANAGED" # For Global External HTTP(S) Load Balancer

  # Optional: Assign a static IP address. If null, an ephemeral IP will be used.
  ip_address = var.ip_address_self_link # To be defined in variables.tf, can be null or a self_link to a google_compute_global_address
}

resource "google_compute_firewall" "allow_lb_hc" {
  project       = var.project_id # To be defined in variables.tf
  name          = "${var.lb_name}-allow-lb-hc" # To be defined in variables.tf, "-hc" for health check & LB
  network       = var.network_self_link # To be defined in variables.tf

  direction     = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [var.backend_service_port] # To be defined in variables.tf (e.g., "8080", "9092")
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"] # Standard GCP LB and Health Check source IP ranges
  target_tags   = [var.backend_instance_tag] # To be defined in variables.tf (e.g., "websocket-backend")

  description = "Allow traffic from GCP Load Balancer and Health Checkers to backend instances."
}
