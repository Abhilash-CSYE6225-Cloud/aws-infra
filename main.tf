provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "vpc_${var.aws_profile}"
  }
}

resource "aws_subnet" "public_subnets" {
  count             = length(data.aws_availability_zones.available.names) > 2 ? 3 : 2
  cidr_block        = "${var.subnet_prefix}.${count.index + 1}.${var.subnet_suffix}"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Type = var.public_tag
    Name = "${var.public_subnet_name}_${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(data.aws_availability_zones.available.names) > 2 ? 3 : 2
  cidr_block        = "${var.subnet_prefix}.${count.index + 4}.${var.subnet_suffix}"
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Type = var.private_tag
    Name = "${var.private_subnet_name}_${count.index + 1}"
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "internet_gateway_${var.aws_profile}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.public_route_table_cidr
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "${var.public_tag}_routetable_${var.aws_profile}"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.private_tag}_routetable_${var.aws_profile}"
  }
}

resource "aws_route_table_association" "public_subnets_association" {
  count          = length(aws_subnet.public_subnets.*.id)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnets_association" {
  count          = length(aws_subnet.private_subnets.*.id)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
resource "aws_instance" "ec2-webapp-dev" {
  count                       = 1
  ami                         = "ami-0ac95c37147119448"
  key_name                    = aws_key_pair.example.key_name
  instance_type               = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.application.id]
  ebs_optimized               = false
  iam_instance_profile = aws_iam_instance_profile.s3_access_instance_profile.name

  root_block_device {
    volume_size           = 50
    volume_type           = "gp2"
    delete_on_termination = true
  }
  disable_api_termination = false
  tags = {
    Name = var.ec2_tag_name
  }

  #Sending User Data to EC2
  user_data = <<EOT
#!/bin/bash
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=Webapp Service
After=network.target

[Service]
Environment="NODE_ENV=dev"
Environment="DB_PORT=3306"
Environment="DB_DIALECT=mysql"
Environment="DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}"
Environment="DB_USER=${aws_db_instance.rds_instance.username}"
Environment="DB_PASSWORD=${aws_db_instance.rds_instance.password}"
Environment="DB=${aws_db_instance.rds_instance.db_name}"
Environment="AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}"
Environment="AWS_REGION=${var.aws_region}"

Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user/webapp
ExecStart=/usr/bin/node listener.js
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/webapp.service
EOF


sudo systemctl daemon-reload
sudo systemctl start webapp.service
sudo systemctl enable webapp.service

echo 'export NODE_ENV=dev' >> /home/ec2-user/.bashrc,
echo 'export PORT=3000' >> /home/ec2-user/.bashrc,
echo 'export DB_DIALECT=mysql' >> /home/ec2-user/.bashrc,
echo 'export DB_HOST=${element(split(":", aws_db_instance.rds_instance.endpoint), 0)}' >> /home/ec2-user/.bashrc,
echo 'export DB_USERNAME=${aws_db_instance.rds_instance.username}' >> /home/ec2-user/.bashrc,
echo 'export DB_PASSWORD=${aws_db_instance.rds_instance.password}' >> /home/ec2-user/.bashrc,
echo 'export DB_NAME=${aws_db_instance.rds_instance.db_name}' >> /home/ec2-user/.bashrc,
echo 'export AWS_BUCKET_NAME=${aws_s3_bucket.webapp-s3.bucket}' >> /home/ec2-user/.bashrc,
echo 'export AWS_REGION=${var.aws_region}' >> /home/ec2-user/.bashrc,
source /home/ec2-user/.bashrc
EOT

}
resource "aws_iam_role" "s3_access_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_instance_profile" "s3_access_instance_profile" {
  name = "s3_access_instance_profile"
  role = aws_iam_role.s3_access_role.name

  tags = {
    Terraform = "true"
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "WebAppS3"
  description = "Policy to allow access to S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.webapp-s3.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.webapp-s3.bucket}/*"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "s3_access_role_policy_attachment" {
  policy_arn = aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.s3_access_role.name
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "rds_subnet_group"
  subnet_ids = [
    aws_subnet.private_subnets[0].id,
    aws_subnet.private_subnets[1].id,
    aws_subnet.private_subnets[2].id
  ]
  description = "Subnet group for the RDS instance"
}

# RDS Instance
resource "aws_db_instance" "rds_instance" {
  db_name                = var.DB_NAME
  identifier             = var.DB_IDENTIFIER
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  multi_az               = false
  username               = var.DB_USERNAME
  password               = var.DB_PASSWORD
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.rds_parameter_group.name
  allocated_storage      = 20
  skip_final_snapshot    = true
  #   engine_version         = "5.7"

  tags = {
    Name = "csye6225_rds"
  }
}

# RDS Parameter Group
resource "aws_db_parameter_group" "rds_parameter_group" {
  name_prefix = "rds-parameter-group"
  family      = "mysql8.0"
  description = "RDS DB parameter group for MySQL 8.0"

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "268435456"
  }
}

resource "aws_security_group_rule" "rds_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database_security_group.id
  source_security_group_id = aws_security_group.application.id
}

resource "aws_security_group_rule" "rds_egress" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database_security_group.id
  source_security_group_id = aws_security_group.application.id
}

resource "aws_security_group_rule" "ec2_ingress" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.application.id
  source_security_group_id = aws_security_group.database_security_group.id
}
resource "random_uuid" "image_uuid" {}

resource "aws_s3_bucket" "webapp-s3" {
  bucket = "webapp-s3-${random_uuid.image_uuid.result}"
  # acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "access_bucket" {
  bucket = aws_s3_bucket.webapp-s3.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.webapp-s3.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.webapp-s3.id
  rule {
    id     = "transition-objects-to-standard-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
resource "aws_security_group" "application" {
  name        = var.security_group
  description = "security group for ec2-webapp-dev"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.security_group
  }
  
}

resource "aws_security_group" "database_security_group" {
  name_prefix = "database-"
  description = "Security group for RDS Instance"
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "database-security-group"
  }
}