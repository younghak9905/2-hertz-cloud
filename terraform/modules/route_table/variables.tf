variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to associate the route table with"
  type        = string
}

variable "is_public" {
  description = "Whether this is a public route table"
  type        = bool
}

variable "igw_id" {
  description = "Internet Gateway ID (required if is_public = true)"
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID (required if is_public = false)"
  type        = string
  default     = null
}