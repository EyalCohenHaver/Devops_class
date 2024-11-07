#Monitoring ec2
resource "aws_instance" "Monitoring" {
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  key_name               = "vockey"
  subnet_id              = aws_subnet.private_subnets[0].id
  depends_on             = [aws_instance.Bastion,aws_nat_gateway.nat_gw]
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  provisioner "file" {
    source      = "./monitoring"
    destination = "/home/ec2-user"

    connection {
      type         = "ssh"
      host         = self.private_ip
      user         = "ec2-user"
      private_key  = file("/labsuser.pem")
      bastion_host = aws_instance.Bastion.public_ip
    }
  }
  user_data = file("./monitoringBash.sh")
  tags = {
    Name = "Monitoring"
  }
}

#Security Group
resource "aws_security_group" "monitoring_sg" {
  name   = "monitoring_sg"
  vpc_id = aws_vpc.project-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "IPv4 route Open to Public Internet"
  }
}