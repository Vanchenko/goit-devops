output "s3_bucket_name" {
  description = "Ім'я S3-бакета"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN S3-бакета"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_url" {
  description = "URL S3-бакета"
  value       = "https://${aws_s3_bucket.terraform_state.bucket_regional_domain_name}"
}

output "dynamodb_table_name" {
  description = "Ім'я таблиці DynamoDB"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_arn" {
  description = "ARN таблиці DynamoDB"
  value       = aws_dynamodb_table.terraform_locks.arn
}
