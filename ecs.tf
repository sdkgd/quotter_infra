#####################################################
# ECS Cluster
#####################################################

resource "aws_ecs_cluster" "this" {
  name = "${local.app_name}-app-cluster"
}

#####################################################
# ECS Task Execution Role
#####################################################

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.app_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Principal":{
          "Service":"ecs-tasks.amazonaws.com"
        }
        "Action":"sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy" "ecs_task_execution_policy" {
  arn="arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution-role-policy-attachment" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_policy.arn
}

resource "aws_iam_policy" "service_discovery" {
  policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect": "Allow",
        "Action": [
            "servicediscovery:RegisterInstance",
            "servicediscovery:DeregisterInstance",
            "servicediscovery:ListServices",
            "servicediscovery:GetService",
            "servicediscovery:GetInstancesHealthStatus",
            "servicediscovery:DiscoverInstances"
        ],
        "Resource": "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution-role-service-discovery-policy-attachment" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.service_discovery.arn
}

#####################################################
# Cloudwatch Log Group
#####################################################

resource "aws_cloudwatch_log_group" "web" {
  name = "/ecs/${local.app_name}/web"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "php" {
  name = "/ecs/${local.app_name}/php"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "next" {
  name = "/ecs/${local.app_name}/next"
  retention_in_days = 30
}

#####################################################
# ECS Task Definition
#####################################################

resource "aws_ecs_task_definition" "web" {
  family = "${local.app_name}-web"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name="web"
      image="${aws_ecr_repository.web.repository_url}:latest"
      portMappings=[
        {
          containerPort:3030
          protocol:"tcp"
        },
        {
          containerPort:9090
          protocol:"tcp"
        }
      ]
      logConfiguration={
        logDriver="awslogs"
        options={
          awslogs-region:"ap-northeast-1"
          awslogs-group:"/ecs/${local.app_name}/web"
          awslogs-stream-prefix:"ecs"
        }
      }
    },
  ])
}

resource "aws_ecs_task_definition" "php" {
  family = "${local.app_name}-php"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name="php"
      image="${aws_ecr_repository.php.repository_url}:latest"
      logConfiguration={
        logDriver="awslogs"
        options={
          awslogs-region:"ap-northeast-1"
          awslogs-group:"/ecs/${local.app_name}/php"
          awslogs-stream-prefix:"ecs"
        }
      }
      secrets=[
        {
          name="APP_KEY"
          valueFrom="/${local.app_name}/APP_KEY"
        },
        {
          name="DB_NAME"
          valueFrom="/${local.app_name}/DB_NAME"
        },
        {
          name="DB_USERNAME"
          valueFrom="/${local.app_name}/DB_USERNAME"
        },
        {
          name="DB_PASSWORD"
          valueFrom="/${local.app_name}/DB_PASSWORD"
        },
        {
          name="DB_HOST"
          valueFrom="/${local.app_name}/DB_HOST"
        },
        {
          name="AWS_BUCKET"
          valueFrom="/${local.app_name}/AWS_BUCKET"
        },
      ]
      environmentFiles=[
        {
          value="arn:aws:s3:::${local.identifier}-${local.app_name}-env-file/php/.prod.env"
          type="s3"
        }
      ]
    }
  ])
}

resource "aws_ecs_task_definition" "next" {
  family = "${local.app_name}-next"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name="next"
      image="${aws_ecr_repository.next.repository_url}:latest"
      logConfiguration={
        logDriver="awslogs"
        options={
          awslogs-region:"ap-northeast-1"
          awslogs-group:"/ecs/${local.app_name}/next"
          awslogs-stream-prefix:"ecs"
        }
      }
      environmentFiles=[
        {
          value="arn:aws:s3:::${local.identifier}-${local.app_name}-env-file/next/.env"
          type="s3"
        }
      ]
    }
  ])
}

#####################################################
# ECS Service
#####################################################

resource "aws_ecs_service" "web" {
  name = "${local.app_name}-web"
  cluster = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.web.arn
  desired_count = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200
  enable_execute_command = true
  load_balancer {
    container_name = "web"
    container_port = 3030
    target_group_arn = aws_lb_target_group.ecs.arn
  }
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.vpc.id
    ]
    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id
    ]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base = 1
    weight = 1
  }
  service_registries {
    registry_arn = aws_service_discovery_service.services["web"].arn
  }
  depends_on = [aws_service_discovery_service.services]
}

resource "aws_ecs_service" "php" {
  name = "${local.app_name}-php"
  cluster = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.php.arn
  desired_count = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200
  enable_execute_command = true
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.vpc.id
    ]
    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id
    ]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base = 1
    weight = 1
  }
  service_registries {
    registry_arn = aws_service_discovery_service.services["php"].arn
  }
  depends_on = [aws_service_discovery_service.services]
}

resource "aws_ecs_service" "next" {
  name = "${local.app_name}-next"
  cluster = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.next.arn
  desired_count = 2
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent = 200
  enable_execute_command = true
  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.vpc.id
    ]
    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id
    ]
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base = 1
    weight = 1
  }
  service_registries {
    registry_arn = aws_service_discovery_service.services["next"].arn
  }
  depends_on = [aws_service_discovery_service.services]
}

#####################################################
# SSM Access Policy
#####################################################

data "aws_caller_identity" "current"{}
data "aws_region" "current" {}

resource "aws_iam_policy" "ssm" {
  name = "${local.app_name}-ssm"
  policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Action":[
          "ssm:GetParameters",
          "ssm:GetParameter",
        ]
        "Resource":"arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/${local.app_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm.arn
}

#####################################################
# ECS Task Role
#####################################################

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.app_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Principal":{
          "Service":"ecs-tasks.amazonaws.com"
        }
        "Action":"sts:AssumeRole"
      }
    ]
  })
}

#####################################################
# Policy for using ECS Exec
#####################################################

resource "aws_iam_policy" "ssm_messages" {
  name = "${local.app_name}-ssm-messages"
  policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Action":[
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_messages" {
  role = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ssm_messages.arn
}