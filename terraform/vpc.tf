resource "aws_vpc" "umami-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "umami-poc-vpc"
  }
}

resource "aws_subnet" "umami-subnet-a" {
  vpc_id               = aws_vpc.umami-vpc.id
  cidr_block           = "10.0.1.0/24"
  availability_zone_id = "euw1-az1"

  map_public_ip_on_launch = true

  tags = {
    Name = "umami-poc-subnet-a"
  }
}


resource "aws_subnet" "umami-subnet-b" {
  vpc_id               = aws_vpc.umami-vpc.id
  cidr_block           = "10.0.2.0/24"
  availability_zone_id = "euw1-az2"

  map_public_ip_on_launch = true

  tags = {
    Name = "umami-poc-subnet-b"
  }
}

resource "aws_internet_gateway" "umami-igw" {
  vpc_id = aws_vpc.umami-vpc.id

  tags = {
    Name = "umami-poc-igw"
  }
}

resource "aws_route_table" "umami-rt" {
  vpc_id = aws_vpc.umami-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.umami-igw.id
  }
}

resource "aws_route_table_association" "umami-rt-assoc-a" {
  subnet_id      = aws_subnet.umami-subnet-a.id
  route_table_id = aws_route_table.umami-rt.id
}


resource "aws_route_table_association" "umami-rt-assoc-b" {
  subnet_id      = aws_subnet.umami-subnet-b.id
  route_table_id = aws_route_table.umami-rt.id
}

