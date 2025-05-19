resource "aws_security_group" "sg-openvpn" {
  name        = "${var.name}-sg"
  description = "Security group for OpenVPN"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Admin UI"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Client UI"
  }

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "VPN tunnel"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.env}-sg-${var.name}"
    Component = "sg-openvpn"
}
}

resource "aws_instance" "openvpn" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg-openvpn.id]
  key_name                    = var.key_name

  tags = {
    Name      = "${var.env}-ec2-${var.name}"
    Component = "ec2-openvpn"
  }

  user_data = var.user_data

   lifecycle {
    ignore_changes = [ami, user_data]
  }

  
}