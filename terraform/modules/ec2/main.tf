resource "aws_security_group" "sg-ec2" {
  name        = "${var.name}-sg"
  description = "Security group for ec2"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.vpn_client_cidr_blocks  # ← 변수로 지정
    description = "SSH from VPN subnet"
  }

   dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = lookup(ingress.value, "description", null)
    }
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  tags = {
    Name      = "${var.env}-sg-${var.name}"
    Component = "sg-ec2"
}
}

resource "aws_instance" "ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg-ec2.id]
  key_name                    = var.key_name

  tags = {
    Name      = "${var.env}-ec2-${var.name}"
    Component = "ec2-openvpn"
  }

  user_data                   = var.user_data
   lifecycle {
    ignore_changes = [ami, user_data]
  }

  
}