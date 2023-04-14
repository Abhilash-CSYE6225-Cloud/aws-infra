# Assignment 9 - Abhilash Gade

## Description
This Terraform script creates a Virtual Private Cloud (VPC) in AWS and creates 3 public and 3 private subnets in different availability zones in the same region. It also creates an Internet Gateway, public and private route tables, and a public route in the public route table. It also creates a EC2 instance with neccessary security groups

## Instructions

* Open the terminal and navigate to the project directory.

* Run `terraform init` to initialize the project and download necessary plugins.
* Run `terraform plan` to review the changes that will be made to your AWS infrastructure.
* Run `terraform destroy` to destroy the VPC

# implemented DNS using route53
 * Configured SSL certificates using AWS CLI 
* `openssl x509 -in prod_abhilashgade_me.crt -outform PEM -out prod_abhilashgade_me.pem`
  `openssl pkcs7 -print_certs -in prod_abhilashgade_me.p7b -out` `prod_abhilashgade_me_ca_bundle.pem`
      `openssl rsa -in prod_abhilashgade_me.key -outform PEM -out prod_abhilashgade_me_private_key.pem`

 * `aws acm import-certificate --certificate fileb://prod_abhilashgade_me.pem --certificate-chain fileb://prod_abhilashgade_me_chain.pem --private-key fileb://private_key.key --profile demo`
  
  

