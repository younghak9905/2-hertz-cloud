variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "lb_name" {
  type        = string
  description = "A name prefix for all load balancer resources."
}

variable "network_self_link" {
  type        = string
  description = "The self_link of the network where the load balancer and backends reside."
}

variable "instance_group_self_link" {
  type        = string
  description = "The self_link of the backend instance group or NEG."
}

variable "managed_ssl_certificate_domains" {
  type        = list(string)
  description = "List of domain names for the Google-managed SSL certificate."
}

variable "backend_service_port" {
  type        = number
  description = "The port number the backend service (WebSocket server) listens on."
  default     = 9092
}

variable "backend_timeout_sec" {
  type        = number
  description = "Backend service timeout in seconds. Recommended to be long for WebSockets."
  default     = 86400 # 24 hours
}

variable "backend_instance_tag" {
  type        = string
  description = "Network tag on backend instances for firewall rule."
}

variable "health_check_path" {
  type        = string
  description = "Request path for HTTP health checks."
  default     = "/healthz"
}

variable "ip_address_self_link" {
  type        = string
  description = "Optional self_link of a reserved static IP address for the forwarding rule."
  default     = null
}
