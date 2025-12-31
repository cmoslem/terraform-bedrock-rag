output "db_endpoint" {
  value = module.aurora_serverless.cluster_endpoint
}

output "db_reader_endpoint" {
  value = module.aurora_serverless.cluster_reader_endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "aurora_endpoint" {
  value = module.aurora_serverless.cluster_endpoint
}

output "aurora_arn" {
  value = module.aurora_serverless.database_arn
}

output "rds_secret_arn" {
  value = module.aurora_serverless.database_secretsmanager_secret_arn
}

output "s3_bucket_name" {
  value = module.s3_bucket.s3_bucket_arn
}