# ============================================================
# Route53 모듈 입력 변수 정의
# DNS 레코드 생성에 필요한 변수들
# ============================================================

# 로드밸런서 DNS 이름
variable "lb_dns_name" {
  description = "CNAME 레코드가 가리킬 로드밸런서의 DNS 이름"
  type        = string
}

# RDS 엔드포인트 주소
variable "rds_endpoint" {
  description = "RDS 데이터베이스 엔드포인트 주소"
  type        = string
  default     = ""
}

# Route53 레코드 설정 맵
variable "records" {
  description = "Route53 레코드 설정 맵 (레코드 키 → 설정)"
  type = map(object({
    zone_id    = string
    name       = string
    ttl        = number
    target_type = string  # "lb" 또는 "rds"
  }))
  default = {}
}
