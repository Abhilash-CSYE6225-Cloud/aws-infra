resource "aws_route53_record" "Abhilashgade_A_record" {
  zone_id = var.aws_profile == "dev" ? var.dev_zone_id : var.prod_zone_id
  name    = var.aws_profile == "dev" ? var.dev_A_record_name : var.prod_A_record_name
  type    = "A"
  ttl     = 60
  records = [aws_eip.elasticip.public_ip]
}