output "ssm_parameter_name" {
  value       = aws_ssm_parameter.this.name
  description = "SSM 파라미터 이름"
}