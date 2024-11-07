# Bastion Security_Group
resource "aws_security_group" "Bastion_sg" {
  name        = "Bastion_sg"
  description = "Bastion_Security_Group"
  vpc_id      = aws_vpc.project-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Open to Public Internet"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
    description      = "IPv6 route Open to Public Internet"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "IPv4 route Open to Public Internet"
  }
  tags = {
    Name = "allow_tls"
  }
}


# Bastion ec2
resource "aws_instance" "Bastion" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  key_name               = "vockey"
  vpc_security_group_ids = [aws_security_group.Bastion_sg.id]
  subnet_id              = aws_subnet.public_subnet[0].id
  user_data              = <<-EOF
    #!/bin/bash
    yum update -y
    EOF
  tags = {
    Name = "Bastion"
  }
}

resource "aws_eip" "ec2-bastion-host-eip" {
  domain = "vpc"
  tags = {
    Name = "ec2-bastion-host-eip"
  }
}

resource "aws_eip_association" "ec2-bastion-host-eip-association" {
  instance_id   = aws_instance.Bastion.id
  allocation_id = aws_eip.ec2-bastion-host-eip.id
}