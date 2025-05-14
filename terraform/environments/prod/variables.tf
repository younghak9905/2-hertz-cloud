variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones to use"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDRs"
}

variable "nat_subnet_cidrs" {
  type        = list(string)
  description = "List of NAT subnet CIDRs"
}