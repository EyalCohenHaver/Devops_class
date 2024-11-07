#internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.project-vpc.id

  tags = {
    Name = "Project VPC IG"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
}

#NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "gw NAT"
  }
  depends_on = [aws_internet_gateway.gw]
}