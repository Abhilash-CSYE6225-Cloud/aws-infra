provider "aws" {
  region = var.region
  profile = var.profile
}

resource "aws_vpc" "vpc_1" {
  cidr_block = var.cidr_vpc[0]

  tags = {
    Name = "${var.vpc_1}"
  }
}

resource "aws_vpc" "vpc_2" {
  cidr_block = var.cidr_vpc[1]

  tags = {
    Name = "${var.vpc_2}"
  }
}

resource "aws_subnet" "public_subnets_1" {
  count = 3
  vpc_id = aws_vpc.vpc_1.id
  cidr_block = "${var.prefix_1}${count.index+1}${var.postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_sname}-${count.index+1}"
  }
}

resource "aws_subnet" "public_subnets_2" {
  count = 3
  vpc_id = aws_vpc.vpc_2.id
  cidr_block = "${var.prefix_2}${count.index+1}${var.postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_sname}-${count.index+1}"
  }
}

resource "aws_subnet" "private_subnets_1" {
  count = 3
  vpc_id = aws_vpc.vpc_1.id
  cidr_block = "${var.prefix_1}${count.index+4}${var.postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_sname}-${count.index+1}"
  }
}

resource "aws_subnet" "private_subnets_2" {
  count = 3
  vpc_id = aws_vpc.vpc_2.id
  cidr_block = "${var.prefix_2}${count.index+4}${var.postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_sname}-${count.index+1}"
  }
}

resource "aws_internet_gateway" "igateway1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.igateway_1}"
  }
}

resource "aws_internet_gateway" "igateway2" {
  vpc_id = aws_vpc.vpc_2.id

  tags = {
    Name = "${var.igateway_2}"
  }
}

resource "aws_route_table" "public_rtable_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = var.routetable_cidr
    gateway_id = aws_internet_gateway.igateway1.id
  }

  tags = {
    Name = "${var.public_rtable_name}"
  }
}

resource "aws_route_table" "public_rtable_2" {
  vpc_id = aws_vpc.vpc_2.id

  route {
    cidr_block = var.routetable_cidr
    gateway_id = aws_internet_gateway.igateway2.id
  }

  tags = {
    Name = "${var.public_rtable_name}"
  }
}

resource "aws_route_table_association" "rtable_associate_public_1" {
  count = 3
  subnet_id = aws_subnet.public_subnets_1[count.index].id
  route_table_id = aws_route_table.public_rtable_1.id
}

resource "aws_route_table_association" "rtable_associate_public_2" {
  count = 3
  subnet_id = aws_subnet.public_subnets_2[count.index].id
  route_table_id = aws_route_table.public_rtable_2.id
}

resource "aws_route_table" "private_rtable_1" {

    vpc_id = aws_vpc.vpc_1.id

    tags = {
        Name = "${var.private_rtable_name}"
    }
  
}

resource "aws_route_table" "private_rtable_2" {

    vpc_id = aws_vpc.vpc_2.id

    tags = {
        Name = "${var.private_rtable_name}"
    }
  
}

resource "aws_route_table_association" "rtable_associate_private_1" {
  count = 3
  subnet_id = aws_subnet.private_subnets_1[count.index].id
  route_table_id = aws_route_table.private_rtable_1.id
}

resource "aws_route_table_association" "rtable_associate_private_2" {
  count = 3
  subnet_id = aws_subnet.private_subnets_2[count.index].id
  route_table_id = aws_route_table.private_rtable_2.id
}