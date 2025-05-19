### Terraform Cloud 관련
terraform {
  backend "remote" {
    organization = "hertz-tuning"

    workspaces {
      name = "terraform-global-ssm-springboot"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

### SSM
module "ssm_db_host" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/DB_HOST"
  description = "MySQL host"
  type        = "String"
  value       = var.db_host
  env         = var.env
}

module "ssm_db_port" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/DB_PORT"
  description = "MySQL port"
  type        = "String"
  value       = var.db_port
  env         = var.env
}

module "ssm_db_name" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/DB_NAME"
  description = "MySQL database name"
  type        = "String"
  value       = var.db_name
  env         = var.env
}

module "ssm_db_username" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/DB_USERNAME"
  description = "MySQL username"
  type        = "String"
  value       = var.db_username
  env         = var.env
}

module "ssm_db_password" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/DB_PASSWORD"
  description = "MySQL password"
  type        = "SecureString"
  value       = var.db_password
  env         = var.env
}

module "ssm_swagger_enabled" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/SWAGGER_ENABLED"
  description = "Enable Swagger in local only"
  type        = "String"
  value       = var.swagger_enabled
  env         = var.env
}

module "ssm_redis_host" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/REDIS_HOST"
  description = "Redis host"
  type        = "String"
  value       = var.redis_host
  env         = var.env
}

module "ssm_redis_port" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/REDIS_PORT"
  description = "Redis port"
  type        = "String"
  value       = var.redis_port
  env         = var.env
}

module "ssm_redis_password" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/REDIS_PASSWORD"
  description = "Redis password"
  type        = "SecureString"
  value       = var.redis_password
  env         = var.env
}

module "ssm_kakao_client_id" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/KAKAO_CLIENT_ID"
  description = "Kakao OAuth client ID"
  type        = "SecureString"
  value       = var.kakao_client_id
  env         = var.env
}

module "ssm_redirect_url_prod" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/REDIRECT_URL_PROD"
  description = "Redirect URL for production"
  type        = "String"
  value       = var.redirect_url_prod
  env         = var.env
}

module "ssm_redirect_url_dev" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/REDIRECT_URL_DEV"
  description = "Redirect URL for development"
  type        = "String"
  value       = var.redirect_url_dev
  env         = var.env
}

module "ssm_jwt_secret" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/JWT_SECRET"
  description = "JWT signing secret"
  type        = "SecureString"
  value       = var.jwt_secret
  env         = var.env
}

module "ssm_ai_server_ip_dev" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/AI_SERVER_IP_DEV"
  description = "AI 서버 주소 (dev)"
  type        = "String"
  value       = var.ai_server_ip_dev
  env         = var.env
}

module "ssm_ai_server_ip_prod" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/backend/AI_SERVER_IP_PROD"
  description = "AI 서버 주소 (prod)"
  type        = "String"
  value       = var.ai_server_ip_prod
  env         = var.env
}