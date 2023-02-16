variable "region" {
    type = string
    description = "AWS region which is closest"
    default = "us-east-1"
}

variable "profile" {
    type = string
    description = "AWS working profile"
    default = "dev"
}

variable "cidr_vpc" {
    type = list(string)
    description = "The CIDR block of the VPC"
    default = ["10.0.0.0/16", "10.1.0.0/16"]
}

variable "availability_zones" {
    type = list(string)
    description = "Subnets availability zones"
    default = ["a", "b", "c"]
}

variable "vpc_1" {
    type = string
    description = "Name of the VPC"
    default = "vpc_aws_1"
}

variable "vpc_2" {
    type = string
    description = "Name of the VPC"
    default = "vpc_aws_2"
}

variable "public_sname" {
    type = string
    description = "Name of the public subnet"
    default = "public-aws-subnet"
}

variable "private_sname" {
    type = string
    description = "Name of the private subnet"
    default = "private-aws-subnet"
}

variable "igateway_1" {
    type = string
    description = "Name of the gateway"
    default = "internet-gw-1"
}

variable "igateway_2" {
    type = string
    description = "Name of the gateway"
    default = "internet-gw-2"
}

variable "public_rtable_name" {
    type = string
    description = "Name of the public route table"
    default = "public-aws-route-table"
}

variable "private_rtable_name" {
    type = string
    description = "Name of the private route table"
    default = "private-aws-route-table"
}

variable "routetable_cidr" {
    type = string
    description = "The CIDR block of the route table"
    default = "0.0.0.0/0"
}

variable "prefix_1" {
    type = string
    description = "prefix of the cidr"
    default = "10.0."
}

variable "prefix_2" {
    type = string
    description = "prefix of the cidr"
    default = "10.1."
}

variable "postfix" {
    type = string
    description = "postfix of the cidr"
    default = ".0/24"
}