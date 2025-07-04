variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "subnet_self_link" {
  type = string
}


variable "startup_tpl" {
  type = string
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "desired" {
  type    = number
  default = 2
}

variable "min" {
  type    = number
  default = 1
}

variable "max" {
  type    = number
  default = 2
}

variable "cpu_target" {
  type    = number
  default = 0.8
}

variable "health_check" {
  type = string
}

variable "use_ecr" {
  type    = bool
  default = false
}

variable "aws_region" {
  type    = string
  default = ""
}

variable "aws_access_key_id" {
  type    = string
  default = ""
}
variable "aws_secret_access_key" {
  type    = string
  default = ""
}


variable "tags" {
  type    = list(string)
  default = []
  
}

variable "port_http" {
  type    = number
  default = 80
  
}
variable "project_id" {
  type = string
  default = ""
}

variable "deploy_ssh_public_key" {
  type    = string
  default = ""
  
}

variable "is_dev_env" {
  description = "개발 환경 여부 (true면 완전 교체 배포)"
  type        = bool
  default     = false
}

variable "port_ws" {
  description = "Port for WebSocket connections"
  type        = number
  default     = 9100
}