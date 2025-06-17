#####################################################
# Security Group for External
#####################################################

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name="${local.app_name}-web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_ingress_rule_http" {
  security_group_id = aws_security_group.web.id
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "web_ingress_rule_https" {
  security_group_id = aws_security_group.web.id
  from_port = 443
  to_port = 443
  ip_protocol = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "web_egress_rule" {
  security_group_id = aws_security_group.web.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

#####################################################
# Security Group for Internal
#####################################################

resource "aws_security_group" "vpc" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name="${local.app_name}-vpc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_ingress_rule" {
  security_group_id = aws_security_group.vpc.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "vpc_egress_rule" {
  security_group_id = aws_security_group.vpc.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

#####################################################
# Security Group for RDS
#####################################################

resource "aws_security_group" "db" {
  name = "${local.app_name}-db"
  vpc_id = aws_vpc.this.id
  tags = {
    name="${local.app_name}-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_ingress_rule" {
  security_group_id = aws_security_group.db.id
  from_port = 3306
  to_port = 3306
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "db_egress_rule" {
  security_group_id = aws_security_group.db.id
  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}