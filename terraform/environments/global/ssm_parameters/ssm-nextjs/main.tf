module "ssm_next_api_base_url_prod" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/nextjs/NEXT_PUBLIC_API_BASE_URL_PROD"
  description = "Next.js API base URL for production"
  type        = "String"
  value       = var.next_public_api_base_url_prod
  env         = var.env
}

module "ssm_next_api_base_url_dev" {
  source      = "../../../../modules/ssm_parameter"
  name        = "/global/nextjs/NEXT_PUBLIC_API_BASE_URL_DEV"
  description = "Next.js API base URL for development"
  type        = "String"
  value       = var.next_public_api_base_url_dev
  env         = var.env
}