#####################################################
# Env file Bucket and Policy
#####################################################

resource "aws_s3_bucket" "env_file" {
  bucket = "${local.identifier}-${local.app_name}-env-file"
}

resource "aws_iam_policy" "s3_env_file" {
  name = "${local.app_name}-env-file"
  policy = jsonencode(
    {
      "Version":"2012-10-17"
      "Statement":[
        {
          "Effect":"Allow"
          "Action":"s3:GetObject"
          "Resource":"${aws_s3_bucket.env_file.arn}/*"
        },
        {
          "Effect":"Allow"
          "Action":"s3:GetBucketLocation"
          "Resource":aws_s3_bucket.env_file.arn
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_s3_env_file" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.s3_env_file.arn
}

#####################################################
# Static file Bucket and Policy
#####################################################

resource "aws_s3_bucket" "static_file" {
  bucket = "${local.identifier}-${local.app_name}-static-file"
}

resource "aws_s3_bucket_public_access_block" "s3_static_file" {
  bucket = aws_s3_bucket.static_file.id
  block_public_acls = true
  block_public_policy = false
  ignore_public_acls = true
  restrict_public_buckets = false
}

resource "aws_iam_policy" "s3_static_file" {
  name = "${local.app_name}-static-file"
  policy = jsonencode(
    {
      "Version":"2012-10-17"
      "Statement":[
        {
          "Effect":"Allow"
          "Action":[
            "s3:PutObject",
            "s3:GeObject",
            "s3:DeleteObject",
          ]
          "Resource":"${aws_s3_bucket.static_file.arn}/*"
        },
        {
          "Effect":"Allow"
          "Action":"s3:GetBucketLocation"
          "Resource":aws_s3_bucket.static_file.arn
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_static_file" {
  role = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3_static_file.arn
}

resource "aws_ssm_parameter" "aws_bucket" {
  name = "/${local.app_name}/AWS_BUCKET"
  type = "String"
  value = aws_s3_bucket.static_file.bucket
}

data "aws_iam_policy_document" "s3_static_file_public_access"{
  statement {
    principals {
      type = "*"
      identifiers = ["*"]
    }
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static_file.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "s3_static_file_public_access" {
  bucket = aws_s3_bucket.static_file.id
  policy = data.aws_iam_policy_document.s3_static_file_public_access.json
}