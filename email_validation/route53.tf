resource "aws_route53_zone" "email_domain" {
  name = var.email_domain
}