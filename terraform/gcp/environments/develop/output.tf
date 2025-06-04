# 인스턴스 그룹 정보
output "instance_groups" {
  description = "Instance group information"
  value = {
    backend_blue   = module.backend_ig.instance_group
    frontend_blue  = module.frontend_ig.instance_group
  }
}
