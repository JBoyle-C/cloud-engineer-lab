terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lab-vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public Subnet A"
    Environment = "Dev"

  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public Subnet B"
    Environment = "Dev"

  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Private Subnet A"
    Environment = "Dev"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Private Subnet B"
    Environment = "Dev"
  }
}

resource "aws_subnet" "data_app_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Data App Subnet A"
    Environment = "Dev"
  }
}

resource "aws_subnet" "data_app_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "Data App Subnet B"
    Environment = "Dev"
  }
}

# This will create the door to the internet and attach it to the VPC 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "lab-igw"
    Environment = "Dev"

  }
}

# Route Table, this will create a route table for the vpc
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "lab-public-rt"
    Environment = "Dev"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id

}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc" # tells AWS this EIP is for use inside a VPC

  tags = {
    Name        = "lab-nat-eip"
    Environment = "Dev"
  }
}

# NAT Gateway in public_subnet_a
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name        = "lab-nat-gw"
    Environment = "Dev"

  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "lab-private-rt"
    Environment = "Dev"
  }
}

# Associate Private Subnets with Private Route Table  
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private.id

}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private.id

}

resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_app_subnet_a.id
  route_table_id = aws_route_table.private.id

}


resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_app_subnet_b.id
  route_table_id = aws_route_table.private.id
}
