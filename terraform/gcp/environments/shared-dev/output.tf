output "vpc_name" {
  value = google_compute_network.shared_vpc.name
}

output "vpc_self_link" {
  value = google_compute_network.shared_vpc.self_link
}

output "subnets" {
  value = [for s in google_compute_subnetwork.shared_subnets : s.self_link]
}

output "firewall_rules" {
  value = local.firewall_rules
}

# shared/output.tf

output "nat_a_subnet_self_link" {
  value = google_compute_subnetwork.shared_subnets["${var.vpc_name}-nat-a"].self_link
}

output "private_subnet_self_link" {
   value = google_compute_subnetwork.shared_subnets["${var.vpc_name}-private-a"].self_link
}


output "nat_a_subnet_info" {
  value = {
    for s in google_compute_subnetwork.shared_subnets :
    s.name => {
      name      = s.name
      self_link = s.self_link
      cidr      = s.ip_cidr_range
    }
    if can(regex("-nat-a", s.name))
  }
}




# Backend Health Check의 self_link
output "hc_backend_self_link" {
  description = "Self link of the backend HTTP health check"
  value       = module.hc_backend.self_link
}

# Frontend Health Check의 self_link
output "hc_frontend_self_link" {
  description = "Self link of the frontend HTTP health check"
  value       = module.hc_frontend.self_link
}

output "hc_websocket_self_link" {
  description = "Self link of the websocket health check"
  value       = module.hc_websocket.self_link
}

output "mysql_data_disk_self_link" {
  description = "MySQL 데이터 저장용 Persistent Disk (self_link)"
  value       = google_compute_disk.mysql_data.self_link
}

output "mysql_data_disk_id" {
  description = "MySQL 데이터 저장용 Persistent Disk (id)"
  value       = google_compute_disk.mysql_data.id
}




output "dev_external_lb_ip_address" {
  description = "Dev 환경 External LB에 할당된 Global IP"
  value       = google_compute_global_address.dev_external_lb_ip.address
}

output "dev_external_lb_ip_self_link" {
  description = "Dev 환경 External LB IP의 Self Link"
  value       = google_compute_global_address.dev_external_lb_ip.self_link
}


output "ilb_proxy_subnet_self_link" {
  description = "Internal Load Balancer용 Proxy Subnet의 Self Link"
  value       = google_compute_subnetwork.ilb_proxy_subnet.self_link
  
}