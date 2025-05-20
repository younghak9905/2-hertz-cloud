variable "name" {
  type        = string
  description = "리소스 네이밍 prefix"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID for ec2"
}

variable "vpn_client_cidr_blocks" {
  description = "OpenVPN 서버 또는 클라이언트 IP 대역"
  type        = list(string)
  default     = []  # 기본값은 현재 예시 대역
}

variable "ami_id" {
  type        = string
  description = "OpenVPN AMI ID (Marketplace BYOL)"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "env" {
  description = "Environment 이름 (dev, prod 등)"
  type        = string
}

variable "user_data" {
  description = "User data script for OpenVPN"
  type        = string
  default     = null
  
}

variable "ingress_rules" {
  description = "리스트 형태의 추가 ingress 규칙"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = optional(string)
  }))
  default = []
}