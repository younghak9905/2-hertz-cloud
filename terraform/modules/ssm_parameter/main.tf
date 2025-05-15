resource "aws_ssm_parameter" "this" {
  name        = var.name
  description = var.description
  type        = var.type
  value       = var.value
  overwrite   = true

  tags = {
    Name      = "${var.env}-${var.name}-ssm"
    Component = "ssm-parameter"
  }
}