#####################################################
# ECR Repository
#####################################################

resource "aws_ecr_repository" "web" {
  name="${local.app_name}-web"
}

resource "aws_ecr_repository" "php" {
  name="${local.app_name}-php"
}

#####################################################
# ECR Lifecycle Policy
#####################################################

resource "aws_ecr_lifecycle_policy" "web" {
  repository = aws_ecr_repository.web.name
  policy = jsonencode(
    {
      "rules":[
        {
          "rulePriority":1,
          "description":"Keep last 5 images",
          "selection":{
            "tagStatus":"any",
            "countType":"imageCountMoreThan",
            "countNumber":5
          },
          "action":{
            "type":"expire"
          }
        }
      ]
    }
  )
}

resource "aws_ecr_lifecycle_policy" "php" {
  repository = aws_ecr_repository.php.name
  policy = jsonencode(
    {
      "rules":[
        {
          "rulePriority":1,
          "description":"Keep last 5 images",
          "selection":{
            "tagStatus":"any",
            "countType":"imageCountMoreThan",
            "countNumber":5
          },
          "action":{
            "type":"expire"
          }
        }
      ]
    }
  )
}