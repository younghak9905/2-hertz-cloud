##############################
# 필수 입력
##############################
variable "name" {
  description = "Backend Service 이름"
  type        = string
}

variable "health_check" {
  description = "Health Check self_link"
  type        = string
}

variable "description" {
  description = "트래픽 변경 값 반영을 위한 설정"
  type        = string
}

##############################
# backends 리스트
##############################
variable "backends" {
  description = "목표 백엔드 목록"
  type = list(object({
    instance_group   = string
    balancing_mode   = optional(string, "UTILIZATION") # CONNECTION | RATE | UTILIZATION
    capacity_scaler  = optional(number, 1.0)        # 0.0–1.0, 기본 1.0
    # weight           = optional(number, 100)        # 기본 100
  }))
}

##############################
# 선택 입력
##############################
variable "protocol" {
  type    = string
  default = "HTTP"
}

variable "port_name" {
  type    = string
  default = "http"
}

variable "timeout_sec" {
  type    = number
  default = 3600
}

variable "connection_draining_sec" {
  type    = number
  default = 300
}

variable "session_affinity" {
  description = "Session affinity scheme for the backend service. Valid values are NONE, CLIENT_IP, GENERATED_COOKIE, HEADER_FIELD, HTTP_COOKIE. For WebSockets, GENERATED_COOKIE or CLIENT_IP is recommended."
  type        = string
  default     = "NONE"
}

variable "affinity_cookie_ttl_sec" {
  description = "If session_affinity is GENERATED_COOKIE, this is the TTL in seconds for the generated cookie. Set to 0 to make it a session cookie. If null, the default behavior of the provider for this field will be used when session_affinity is GENERATED_COOKIE."
  type        = number
  default     = null
}

variable "log_enable" {
  type    = bool
  default = false
}

variable "log_sample_rate" {
  type    = number
  default = 1.0
}