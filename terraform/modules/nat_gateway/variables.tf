variable "subnet_id" {
  description = "The ID of the public subnet in which to launch the NAT Gateway"
  type        = string
}

variable "env" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}