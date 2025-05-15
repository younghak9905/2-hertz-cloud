output "openvpn_instance_id" {
  value = aws_instance.openvpn.id
}

output "public_ip" {
  value = aws_instance.openvpn.public_ip
}

output "admin_ui_url" {
  value = "https://${aws_instance.openvpn.public_ip}:943/admin"
}