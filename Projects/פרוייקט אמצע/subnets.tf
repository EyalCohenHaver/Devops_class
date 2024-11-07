#public subnet
resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.project-vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index + 1)

  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

#privte subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.project-vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)
  tags = {
    Name = "Private Subnet ${count.index + 1}"
  }
}

#route table for pablic subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

#attaching public RT to subnet
resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet1_asso" {
  subnet_id      = aws_subnet.public_subnet[1].id
  route_table_id = aws_route_table.public_rt.id
}

#route table for privte subnets
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "Privte Route Table"
  }
}

#attaching privte RT to subnet
resource "aws_route_table_association" "private_subnet_asso" {
  count          = 3
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}