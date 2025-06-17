#####################################################
# ACM
#####################################################

resource "aws_acm_certificate" "root" {
  domain_name = local.host_domain
  validation_method = "DNS"
  tags = {
    Name=local.host_domain
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.root.arn
}