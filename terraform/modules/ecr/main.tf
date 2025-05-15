resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true  # 리포지토리 삭제 시 이미지도 함께 삭제

  tags = {
    Name      = "${var.env}-${var.name}-ecr"
    Component = "ecr"
    Env       = var.env
  }
}

# # 30일이 경과된 파일은 삭제
# resource "aws_ecr_lifecycle_policy" "expire_old_images" {
#   repository = aws_ecr_repository.this.name

#   policy = jsonencode({
#     rules = [
#       {
#         rulePriority = 1
#         description  = "Expire images older than 30 days"
#         selection = {
#           tagStatus     = "tagged"
#           countType     = "sinceImagePushed"
#           countUnit     = "days"
#           countNumber   = 30
#         }
#         action = {
#           type = "expire"
#         }
#       }
#     ]
#   })
# }