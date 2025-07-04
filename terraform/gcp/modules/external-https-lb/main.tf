############################################################
# URL Map + HTTPS Proxy + Global Forwarding Rule Module
############################################################

resource "google_compute_managed_ssl_certificate" "this" {
  name = "${var.name}-cert-${var.env}"
  managed {
    domains = var.domains
  }
}

# URL Map 생성 (프론트엔드 및 백엔드 경로별 분기)

resource "google_compute_url_map" "this" {
  name = "${var.name}-url-map-${var.env}"

  # 1) host_rule: 모든 호스트(와일드카드)에서 이 URL Map을 사용
  host_rule {
    hosts        = ["*"]
    path_matcher = "main-matcher"
  }

  # 2) path_matcher: 경로별 라우팅 설정
  path_matcher {
    name            = "main-matcher"
    default_service = var.frontend_service  # "/" 이하 기본은 프론트엔드 서비스로

     path_rule {
       paths = [
      "/ws",   # wss://…/ws
      "/ws/",  # wss://…/ws/
      "/ws/*",
      "/socket.io",   # wss://…/socket.io
      "/socket.io/",  # wss://…/socket.io/
      "/socket.io/*"
    ]
      route_action {
        url_rewrite {
          path_prefix_rewrite = "/socket.io/"
        }
      }
      service = var.websocket_service
    }
    # --- Spring Boot API(기존) ---
    path_rule {
      paths   = ["/api/*"]       # 예: "/api/foo"
      service = var.backend_service
    }

    # --- Server-Sent Events 전용(필요하다면) (/api/sse/* 도 api/*에 포함됨) ---
    # (URL Map 상에서는 /api/*에 매핑되므로 굳이 따로 안 적어도 되지만,
    #  명확히 구분하고 싶다면 아래와 같이 추가해도 무방합니다.)
    # path_rule {
    #   paths   = ["/api/sse/*"]
    #   service = var.backend_service
    # }

    # --- Swagger UI 접근 경로 (새로 추가) ---
    path_rule {
      paths   = ["/swagger-ui/*"]   # 예: "/swagger-ui/index.html"
      service = var.backend_service
    }

    # --- OpenAPI 스펙(/v3/*) --- 
    path_rule {
      paths   = ["/v3/*"]           # 예: "/v3/api-docs"
      service = var.backend_service
    }
  }
  default_service = var.frontend_service

}

resource "google_compute_url_map" "http_redirect_url_map" {
  name = "${var.name}-http-redirect-url-map-${var.env}"

  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}
resource "google_compute_target_https_proxy" "this" {
  name             = "${var.name}-https-proxy-${var.env}"
  url_map          = google_compute_url_map.this.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.this.self_link]
}

resource "google_compute_global_forwarding_rule" "https_fr" {
  name                  = "${var.name}-https-fr-${var.env}"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.this.self_link
  ip_address            = var.lb_ip.address
}


# HTTP Proxy for redirection
resource "google_compute_target_http_proxy" "this" {
  name    = "${var.name}-http-proxy-${var.env}"
  url_map = google_compute_url_map.http_redirect_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_fr" {
  name                  = "${var.name}-http-fr-${var.env}"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.this.self_link
  ip_address            = var.lb_ip.address
}
