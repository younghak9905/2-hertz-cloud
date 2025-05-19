### Terraform Cloud 관련
terraform {
  backend "remote" {
    organization = "hertz-tuning"

    workspaces {
      name = "terraform-global-ssm-gcp"
    }
  }
}

provider "aws" {
  region = var.region
}

### SSM
module "ssm_prod_gcp_project_id" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_PROJECT_ID"
  description = "GCP 프로젝트 ID (prod)"
  type        = "String"
  value       = var.prod_gcp_project_id
  env         = var.env
}

module "ssm_dev_gcp_project_id" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_PROJECT_ID"
  description = "GCP 프로젝트 ID (dev)"
  type        = "String"
  value       = var.dev_gcp_project_id
  env         = var.env
}

module "ssm_gcp_zone" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/GCP_ZONE"
  description = "GCP zone"
  type        = "String"
  value       = var.gcp_zone
  env         = var.env
}

module "ssm_prod_gcp_sa_key" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_SA_KEY"
  description = "GCP 서비스 계정 키 (prod)"
  type        = "SecureString"
  value       = var.prod_gcp_sa_key
  env         = var.env
}

module "ssm_dev_gcp_sa_key" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_SA_KEY"
  description = "GCP 서비스 계정 키 (dev)"
  type        = "SecureString"
  value       = var.dev_gcp_sa_key
  env         = var.env
}

module "ssm_prod_gcp_instance" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_INSTANCE"
  description = "GCP BE 인스턴스 이름 (prod)"
  type        = "String"
  value       = var.prod_gcp_instance
  env         = var.env
}

module "ssm_prod_gcp_instance_ai" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_INSTANCE_AI"
  description = "GCP AI 인스턴스 이름 (prod)"
  type        = "String"
  value       = var.prod_gcp_instance_ai
  env         = var.env
}

module "ssm_dev_gcp_instance" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_INSTANCE"
  description = "GCP BE 인스턴스 이름 (dev)"
  type        = "String"
  value       = var.dev_gcp_instance
  env         = var.env
}

module "ssm_dev_gcp_instance_ai" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_INSTANCE_AI"
  description = "GCP AI 인스턴스 이름 (dev)"
  type        = "String"
  value       = var.dev_gcp_instance_ai
  env         = var.env
}

module "ssm_prod_gcp_host" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_HOST"
  description = "GCP SSH host (prod)"
  type        = "String"
  value       = var.prod_gcp_host
  env         = var.env
}

module "ssm_prod_gcp_host_ai" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/PROD_GCP_HOST_AI"
  description = "GCP AI SSH host (prod)"
  type        = "String"
  value       = var.prod_gcp_host_ai
  env         = var.env
}

module "ssm_dev_gcp_host" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_HOST"
  description = "GCP SSH host (dev)"
  type        = "String"
  value       = var.dev_gcp_host
  env         = var.env
}

module "ssm_dev_gcp_host_ai" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DEV_GCP_HOST_AI"
  description = "GCP AI SSH host (dev)"
  type        = "String"
  value       = var.dev_gcp_host_ai
  env         = var.env
}

module "ssm_ssh_username" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/SSH_USERNAME"
  description = "SSH 접속 계정"
  type        = "String"
  value       = var.ssh_username
  env         = var.env
}

module "ssm_ssh_private_key" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/SSH_PRIVATE_KEY"
  description = "SSH 개인 키"
  type        = "SecureString"
  value       = var.ssh_private_key
  env         = var.env
}

module "ssm_discord_webhook_cicd_url" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/gcp/DISCORD_WEBHOOK_CICD_URL"
  description = "디스코드 CICD 웹훅 주소"
  type        = "SecureString"
  value       = var.discord_webhook_cicd_url
  env         = var.env
}