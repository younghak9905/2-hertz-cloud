output "ec2_instance_id" {
  value = aws_instance.ec2.id
}

output "public_ip" {
  value = aws_instance.openvpn.public_ip
}
