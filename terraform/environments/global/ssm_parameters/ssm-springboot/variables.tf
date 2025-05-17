variable "env"                 { type = string }
variable "db_host"             { type = string }
variable "db_port"             { type = string }
variable "db_name"             { type = string }
variable "db_username"         { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "swagger_enabled"     { type = string }
variable "redis_host"          { type = string }
variable "redis_port"          { type = string }
variable "redis_password" {
  type      = string
  sensitive = true
}
variable "kakao_client_id" {
  type      = string
  sensitive = true
}
variable "redirect_url_prod"   { type = string }
variable "redirect_url_dev"    { type = string }
variable "jwt_secret" {
  type      = string
  sensitive = true
}
variable "ai_server_ip_dev"    { type = string }
variable "ai_server_ip_prod"   { type = string }