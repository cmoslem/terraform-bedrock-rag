resource "aws_iam_role" "bedrock_kb_role" {
  name = "AmazonBedrockExecutionRoleForKnowledgeBase"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "bedrock_kb_policy" {
  name   = "AmazonBedrockKnowledgeBasePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction",
          "rds:DescribeDBClusters"
        ]
        Effect   = "Allow"
        Resource = var.aurora_arn
      },
      {
        Action = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = var.aurora_secret_arn
      },
      {
        Action = "bedrock:InvokeModel"
        Effect = "Allow"
        Resource = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_kb_attachment" {
  role       = aws_iam_role.bedrock_kb_role.name
  policy_arn = aws_iam_policy.bedrock_kb_policy.arn
}

resource "aws_bedrockagent_knowledge_base" "main" {
  name     = var.knowledge_base_name
  role_arn = aws_iam_role.bedrock_kb_role.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1"
    }
  }

  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = var.aurora_secret_arn
      database_name          = var.aurora_db_name
      resource_arn           = var.aurora_arn
      table_name             = var.aurora_table_name
      field_mapping {
        primary_key_field = var.aurora_primary_key_field
        vector_field      = var.aurora_verctor_field
        text_field        = var.aurora_text_field
        metadata_field    = var.aurora_metadata_field
      }
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = "bedrock-kb-${data.aws_caller_identity.current.account_id}"
}

resource "aws_bedrockagent_data_source" "s3_bedrock_bucket" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "s3_bedrock_bucket"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.s3_bucket_arn
    }
  }
  depends_on = [aws_bedrockagent_knowledge_base.main]
}