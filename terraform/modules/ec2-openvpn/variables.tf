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
  description = "Public subnet ID for OpenVPN"
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