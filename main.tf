provider "aws" {
  region  = var.region
  profile = var.profile
}

resource "aws_vpc" "vpc_1" {
  cidr_block = var.vpc_cidr[0]

  tags = {
    Name = "${var.vpc_name_1}"
  }
}

# resource "aws_vpc" "vpc_2" {
#   cidr_block = var.vpc_cidr[1]

#   tags = {
#     Name = "${var.vpc_name_2}"
#   }
# }

resource "aws_subnet" "public_subnets_1" {
  count             = 3
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "${var.subnet_prefix_1}${count.index + 1}${var.subnet_postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index + 1}"
  }
}

# resource "aws_subnet" "public_subnets_2" {
#   count             = 3
#   vpc_id            = aws_vpc.vpc_2.id
#   cidr_block        = "${var.subnet_prefix_2}${count.index + 1}${var.subnet_postfix}"
#   availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

#   tags = {
#     Name = "${var.public_subnet_name}-${count.index + 1}"
#   }
# }

resource "aws_subnet" "private_subnets_1" {
  count             = 3
  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = "${var.subnet_prefix_1}${count.index + 4}${var.subnet_postfix}"
  availability_zone = "${var.region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index + 1}"
  }
}

# resource "aws_subnet" "private_subnets_2" {
#   count             = 3
#   vpc_id            = aws_vpc.vpc_2.id
#   cidr_block        = "${var.subnet_prefix_2}${count.index + 4}${var.subnet_postfix}"
#   availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

#   tags = {
#     Name = "${var.private_subnet_name}-${count.index + 1}"
#   }
# }

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.gateway_name_1}"
  }
}

# resource "aws_internet_gateway" "gw2" {
#   vpc_id = aws_vpc.vpc_2.id

#   tags = {
#     Name = "${var.gateway_name_2}"
#   }
# }

resource "aws_route_table" "public_route_table_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = var.rt_cidr
    gateway_id = aws_internet_gateway.gw1.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

# resource "aws_route_table" "public_route_table_2" {
#   vpc_id = aws_vpc.vpc_2.id

#   route {
#     cidr_block = var.rt_cidr
#     gateway_id = aws_internet_gateway.gw2.id
#   }

#   tags = {
#     Name = "${var.public_rt_name}"
#   }
# }

resource "aws_route_table_association" "rt_associate_public_1" {
  count          = 3
  subnet_id      = aws_subnet.public_subnets_1[count.index].id
  route_table_id = aws_route_table.public_route_table_1.id
}

# resource "aws_route_table_association" "rt_associate_public_2" {
#   count          = 3
#   subnet_id      = aws_subnet.public_subnets_2[count.index].id
#   route_table_id = aws_route_table.public_route_table_2.id
# }

resource "aws_route_table" "private_route_table_1" {

  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.private_rt_name}"
  }

}

# resource "aws_route_table" "private_route_table_2" {

#   vpc_id = aws_vpc.vpc_2.id

#   tags = {
#     Name = "${var.private_rt_name}"
#   }

# }

resource "aws_route_table_association" "rt_associate_private_1" {
  count          = 3
  subnet_id      = aws_subnet.private_subnets_1[count.index].id
  route_table_id = aws_route_table.private_route_table_1.id
}

# resource "aws_route_table_association" "rt_associate_private_2" {
#   count          = 3
#   subnet_id      = aws_subnet.private_subnets_2[count.index].id
#   route_table_id = aws_route_table.private_route_table_2.id
# }

resource "aws_security_group" "application_sec_grp" {
  name_prefix = var.security_grp_name
  vpc_id      = aws_vpc.vpc_1.id

  ingress {
    from_port   = var.ports[0]
    to_port     = var.ports[0]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[1]
    to_port     = var.ports[1]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[2]
    to_port     = var.ports[2]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  ingress {
    from_port   = var.ports[3]
    to_port     = var.ports[3]
    protocol    = var.protocol
    cidr_blocks = [var.rt_cidr]
  }

  egress {
    from_port   = var.ports[4]
    to_port     = var.ports[4]
    protocol    = var.e_protocol
    cidr_blocks = [var.rt_cidr]
  }
}

resource "aws_key_pair" "app_key_pair" {
  key_name   = var.keypair_name
  public_key = file(var.keypair_path)
}

resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = "${var.region}${var.availability_zones[0]}"
  size              = var.ebs_vol_size
  type              = var.ebs_vol_type
  tags = {
    Name = var.ebs_vol_name
  }
}

resource "aws_instance" "prod_ec2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets_1[0].id
  vpc_security_group_ids = [aws_security_group.application_sec_grp.id]
  tags = {
    Name = var.ec2_name
  }
  key_name = aws_key_pair.app_key_pair.key_name

  associate_public_ip_address = true
  disable_api_termination     = false

  connection {
    type        = var.conn_type
    user        = var.user
    private_key = file(var.private_key_path)
    timeout     = var.ssh_timeout
    host        = self.public_ip
  }
}

resource "aws_volume_attachment" "ebs_Attach" {

  device_name = var.device_name
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.prod_ec2.id

}

resource "aws_eip" "ec2_eip" {
  vpc = true
}

resource "aws_eip_association" "ec2_eip_association" {
  instance_id   = aws_instance.prod_ec2.id
  allocation_id = aws_eip.ec2_eip.id
}