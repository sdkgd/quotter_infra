#####################################################
# Route53 Zone
#####################################################

data "aws_route53_zone" "this" {
  name=local.host_domain
}

#####################################################
# Route53 Record
#####################################################

resource "aws_route53_record" "cert_validation" {
  zone_id = data.aws_route53_zone.this.id
  for_each = {
    for dvo in aws_acm_certificate.root.domain_validation_options:dvo.domain_name =>{
      name=dvo.resource_record_name
      record=dvo.resource_record_value
      type=dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name=each.value.name
  records = [each.value.record]
  type=each.value.type
  ttl = 60
}

resource "aws_route53_record" "root_a" {
  name = data.aws_route53_zone.this.name
  type = "A"
  zone_id = data.aws_route53_zone.this.id
  alias {
    evaluate_target_health = true
    name = aws_lb.this.dns_name
    zone_id = aws_lb.this.zone_id
  }
}