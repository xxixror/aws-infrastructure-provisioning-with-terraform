# ============================================================
# Terraform Backend 모듈 출력값
# ============================================================

output "s3_bucket_name" {
  description = "Terraform state를 저장하는 S3 버킷 이름"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "State locking을 위한 DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

