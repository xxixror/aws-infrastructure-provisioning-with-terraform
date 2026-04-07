# Terraform 변수 정의

# EC2 인스턴스 개수 설정
variable "ec2_instance_counts" {
  description = "EC2 인스턴스 개수 설정 (예: { web = 2, db = 1, dns = 0 })"
  type        = map(number)
  default     = {}
}

# 비밀번호 설정 (환경변수에서 읽기)
variable "rds_password" {
  description = "RDS 데이터베이스 인스턴스 비밀번호 (환경변수: RDS_PASSWORD)"
  type        = string
  sensitive   = true
  default     = ""
}
