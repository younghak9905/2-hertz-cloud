### Terraform Cloud 관련
terraform {
  backend "remote" {
    organization = "hertz-tuning"

    workspaces {
      name = "terraform-global-ssm-nextjs"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

### SSM
module "ssm_next_api_base_url_prod" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/frontend/NEXT_PUBLIC_API_BASE_URL_PROD"
  description = "Next.js API base URL for production"
  type        = "String"
  value       = var.next_public_api_base_url_prod
  env         = var.env
}

module "ssm_next_api_base_url_dev" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/frontend/NEXT_PUBLIC_API_BASE_URL_DEV"
  description = "Next.js API base URL for development"
  type        = "String"
  value       = var.next_public_api_base_url_dev
  env         = var.env
}