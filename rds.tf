#####################################################
# DB Subnet Group
#####################################################

resource "aws_db_subnet_group" "this" {
  name = "${local.app_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id,
  ]
}

#####################################################
# SSM Parameter
#####################################################

data "aws_ssm_parameter" "db_name" {
  name = "/${local.app_name}/DB_NAME"
}

data "aws_ssm_parameter" "db_username" {
  name = "/${local.app_name}/DB_USERNAME"
}

data "aws_ssm_parameter" "db_password" {
  name = "/${local.app_name}/DB_PASSWORD"
}

resource "aws_ssm_parameter" "db_host" {
  name = "/${local.app_name}/DB_HOST"
  type = "String"
  value = aws_db_instance.this.endpoint
}

#####################################################
# DB Instance
#####################################################

resource "aws_db_instance" "this" {
  identifier = "${local.app_name}-db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  db_name = data.aws_ssm_parameter.db_name.value
  username = data.aws_ssm_parameter.db_username.value
  password = data.aws_ssm_parameter.db_password.value
  skip_final_snapshot = true

  storage_type = "gp2"
  allocated_storage = 10
  max_allocated_storage = 0

  port = 3306
  multi_az = true
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.this.name
  vpc_security_group_ids = [ aws_security_group.db.id ]
}