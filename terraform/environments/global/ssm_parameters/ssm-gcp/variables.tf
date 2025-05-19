variable "region"                        { type = string }
variable "env"                        { type = string }
variable "prod_gcp_project_id"       { type = string }
variable "dev_gcp_project_id"        { type = string }
variable "gcp_zone"                  { type = string }

variable "prod_gcp_sa_key" {
  type      = string
  sensitive = true
}
variable "dev_gcp_sa_key" {
  type      = string
  sensitive = true
}

variable "prod_gcp_instance"         { type = string }
variable "prod_gcp_instance_ai"      { type = string }
variable "dev_gcp_instance"          { type = string }
variable "dev_gcp_instance_ai"       { type = string }

variable "prod_gcp_host"             { type = string }
variable "prod_gcp_host_ai"          { type = string }
variable "dev_gcp_host"              { type = string }
variable "dev_gcp_host_ai"           { type = string }

variable "ssh_username"              { type = string }
variable "ssh_private_key" {
  type      = string
  sensitive = true
}

variable "discord_webhook_cicd_url" {
  type      = string
  sensitive = true
}