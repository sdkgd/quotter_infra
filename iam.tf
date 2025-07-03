#####################################################
# IAM user for Github Actions
#####################################################

resource "aws_iam_user" "github" {
  name = "${local.app_name}-github"
}

#####################################################
# IAM role for Github Actions
#####################################################

resource "aws_iam_role" "deployer" {
  name = "${local.app_name}-deployer"
  assume_role_policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Principal":{
            "AWS": aws_iam_user.github.arn
        }
        "Action":[
            "sts:AssumeRole",
            "sts:TagSession"
        ]
      }
    ]
  })
}

#####################################################
# ECR policy for deployer
#####################################################

data "aws_iam_policy" "ecr_power_user" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "role_deployer_policy_ecr_power_user" {
  role = aws_iam_role.deployer.name
  policy_arn = data.aws_iam_policy.ecr_power_user.arn
}

#####################################################
# S3 policy for deployer
#####################################################

resource "aws_iam_policy" "s3" {
  policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Effect":"Allow"
        "Action":[
          "s3:GetObject",
          "s3:ListBucket",
        ]
        "Resource":[
          "arn:aws:s3:::cognitobirm-quotter-env-file",
          "arn:aws:s3:::cognitobirm-quotter-env-file/*",
          "arn:aws:s3:::cognitobirm-quotter-task-definition-file",
          "arn:aws:s3:::cognitobirm-quotter-task-definition-file/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_deployer_policy_s3" {
  role = aws_iam_role.deployer.name
  policy_arn = aws_iam_policy.s3.arn
}

#####################################################
# ECS policy for deployer
#####################################################

resource "aws_iam_policy" "ecs" {
  policy = jsonencode({
    "Version":"2012-10-17"
    "Statement":[
      {
        "Sid":"RegisterTaskDefinition"
        "Effect":"Allow"
        "Action":[
          "ecs:RegisterTaskDefinition"
        ]
        "Resource":"*"
      },
      {
        "Sid":"PassRoleInTaskDefinition"
        "Effect":"Allow"
        "Action":[
          "iam:PassRole"
        ]
        "Resource":[
          aws_iam_role.ecs_task_role.arn,
          aws_iam_role.ecs_task_execution_role.arn,
        ]
      },
      {
        "Sid":"DeployService"
        "Effect":"Allow"
        "Action":[
          "ecs:UpdateService",
          "ecs:DescribeServices",
        ]
        "Resource":[
          "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:service/${local.app_name}-app-cluster/${local.app_name}",
          "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:service/${local.app_name}-app-cluster/migration-service",
        ]
      },
      {
        "Sid":"RunTask"
        "Effect":"Allow"
        "Action":[
          "ecs:RunTask"
        ]
        "Resource":[
          "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:task-definition/*"
        ]
      },
      {
        "Sid":"DescribeTasks"
        "Effect":"Allow"
        "Action":[
          "ecs:DescribeTasks"
        ]
        "Resource":[
          "arn:aws:ecs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:task/${local.app_name}-app-cluster/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_deployer_policy_ecs" {
  role = aws_iam_role.deployer.name
  policy_arn = aws_iam_policy.ecs.arn
}