#Server EC2
resource "aws_instance" "Stock_Predict_Server" {
  count                  = 2
  ami                    = "ami-0fff1b9a61dec8a5f"
  instance_type          = "t2.micro"
  key_name               = "vockey"
  depends_on             = [aws_instance.Bastion,aws_nat_gateway.nat_gw]
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  provisioner "file" {
    source      = "./app"
    destination = "/home/ec2-user"

    connection {
      type         = "ssh"
      host         = self.private_ip
      user         = "ec2-user"
      private_key  = file("/labsuser.pem")
      bastion_host = aws_instance.Bastion.public_ip
    }
  }
  subnet_id = aws_subnet.private_subnets[count.index].id
  user_data = file("./serverBash.sh")
  tags = {
    Name = "Stock_Predict_Server"
  }
}

#Security Group
resource "aws_security_group" "server_sg" {
  name   = "server_sg"
  vpc_id = aws_vpc.project-vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}