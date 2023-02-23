variable "region" {
  type        = string
  description = "AWS region which is closest"
  default     = "us-east-1"
}

variable "profile" {
  type        = string
  description = "AWS working profile"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = list(string)
  description = "The CIDR block of the VPC"
  default     = ["10.0.0.0/16", "10.1.0.0/16"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Subnets availability zones"
  default     = ["a", "b", "c"]
}

variable "vpc_name_1" {
  type        = string
  description = "Name of the VPC"
  default     = "vpc_1"
}

variable "vpc_name_2" {
  type        = string
  description = "Name of the VPC"
  default     = "vpc_2"
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public subnet"
  default     = "prod-public-subnet"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private subnet"
  default     = "prod-private-subnet"
}

variable "gateway_name_1" {
  type        = string
  description = "Name of the gateway"
  default     = "internet-gateway-1"
}

variable "gateway_name_2" {
  type        = string
  description = "Name of the gateway"
  default     = "internet-gateway-2"
}

variable "public_rt_name" {
  type        = string
  description = "Name of the public route table"
  default     = "prod-public-route-table"
}

variable "private_rt_name" {
  type        = string
  description = "Name of the private route table"
  default     = "prod-private-route-table"
}

variable "rt_cidr" {
  type        = string
  description = "The CIDR block of the route table"
  default     = "0.0.0.0/0"
}

variable "subnet_prefix_1" {
  type        = string
  description = "prefix of the cidr"
  default     = "10.0."
}

variable "subnet_prefix_2" {
  type        = string
  description = "prefix of the cidr"
  default     = "10.1."
}

variable "subnet_postfix" {
  type        = string
  description = "postfix of the cidr"
  default     = ".0/24"
}

variable "security_grp_name" {
  type        = string
  description = "security group name"
  default     = "prod application"
}

variable "ports" {
  type        = list(number)
  description = "list of ports"
  default     = [22, 80, 443, 3000, 0]
}

variable "protocol" {
  type        = string
  description = "protocol name"
  default     = "tcp"
}

variable "e_protocol" {
  type        = string
  description = "egress protocol name"
  default     = "-1"
}

variable "keypair_name" {
  type        = string
  description = "key-pair name"
  default     = "app_key_pair"
}

variable "keypair_path" {
  type        = string
  description = "key-pair path"
  default     = "~/.ssh/public_key.pem"
}

variable "ebs_vol_size" {
  type        = number
  description = "ebs volume size"
  default     = 50
}

variable "ebs_vol_type" {
  type        = string
  description = "ebs volume type"
  default     = "gp2"
}

variable "instance_type" {
  type        = string
  description = "ebs instance type"
  default     = "t2.micro"
}

variable "conn_type" {
  type        = string
  description = "connection type"
  default     = "ssh"
}

variable "user" {
  type        = string
  description = "user"
  default     = "ec2-user"
}

variable "private_key_path" {
  type        = string
  description = "path for private key"
  default     = "~/.ssh/id_rsa"
}

variable "ssh_timeout" {
  type        = string
  description = "timeout for ssh"
  default     = "2h"
}

variable "device_name" {
  type        = string
  description = "name of device"
  default     = "/dev/sdh"
}

variable "ebs_vol_name" {
  type        = string
  description = "ebs volume name"
  default     = "ebs_volume"
}

variable "ec2_name" {
  type        = string
  description = "name of ec2 instance"
  default     = "prod_ec2"
}

variable "ami_id" {
  type        = string
  description = "ami id for ec2 instance"
}