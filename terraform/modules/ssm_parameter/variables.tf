variable "name" {
  description = "SSM 파라미터 이름 (예: /service/api-key)"
  type        = string
}

variable "description" {
  description = "SSM 파라미터 설명"
  type        = string
  default     = ""
}

variable "type" {
  description = "SSM 파라미터 타입 (String, SecureString, StringList)"
  type        = string
  default     = "SecureString"
}

variable "value" {
  description = "저장할 실제 값 (API 키 등)"
  type        = string
  sensitive   = true
}

variable "env" {
  description = "환경 구분 (예: dev, prod)"
  type        = string
}