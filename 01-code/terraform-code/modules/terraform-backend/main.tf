# ============================================================
# Terraform Remote State Backend 모듈
# S3 버킷과 DynamoDB 테이블을 생성하여 Terraform state를 공유
# ============================================================

# ------------------------------------------------------------
# S3 버킷 생성 (Terraform state 파일 저장용)
# ------------------------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name

  # 실수로 삭제되는 것 방지 (전체 삭제를 위해 주석 처리)
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name        = var.bucket_name
    Purpose     = "Terraform State Storage"
    Environment = "shared"
  }
}

# S3 버킷 버전 관리 (state 파일 이력 관리)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 버킷 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 버킷 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# DynamoDB 테이블 생성 (State Locking용)
# 여러 사람이 동시에 terraform apply를 실행할 때 충돌 방지
# ------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"  # 사용량 기반 과금
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # 실수로 삭제되는 것 방지 (전체 삭제를 위해 주석 처리)
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name        = var.dynamodb_table_name
    Purpose     = "Terraform State Locking"
    Environment = "shared"
  }
}

