variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets (per AZ)"
  type        = list(string)
}

variable "nat_subnet_cidrs" {
  description = "List of CIDRs for NAT subnets (per AZ)"
  type        = list(string)
}

variable "env" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}