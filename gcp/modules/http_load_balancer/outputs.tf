output "load_balancer_ip_address" {
  description = "The IP address of the load balancer."
  value       = google_compute_global_forwarding_rule.default.ip_address
}

output "load_balancer_name" {
  description = "The name of the load balancer (based on the forwarding rule name)."
  value       = google_compute_global_forwarding_rule.default.name
}

output "https_proxy_self_link" {
  description = "The self_link of the HTTPS proxy."
  value       = google_compute_target_https_proxy.default.self_link
}

output "health_check_self_link" {
  description = "The self_link of the health check."
  value       = google_compute_health_check.default.self_link
}

output "backend_service_self_link" {
  description = "The self_link of the backend service."
  value       = google_compute_backend_service.default.self_link
}

output "url_map_self_link" {
  description = "The self_link of the URL map."
  value       = google_compute_url_map.default.self_link
}

output "managed_ssl_certificate_self_link" {
  description = "The self_link of the managed SSL certificate."
  value       = google_compute_managed_ssl_certificate.default.self_link
}
