# ============================================================
# Terraform Backend 모듈 변수 정의
# ============================================================

variable "bucket_name" {
  description = "Terraform state를 저장할 S3 버킷 이름 (전역적으로 고유해야 함)"
  type        = string
}

variable "dynamodb_table_name" {
  description = "State locking을 위한 DynamoDB 테이블 이름"
  type        = string
}

