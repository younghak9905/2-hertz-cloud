output "repository_url" {
  description = "ECR 저장소 URL"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "ECR 저장소 이름"
  value       = aws_ecr_repository.this.name
}