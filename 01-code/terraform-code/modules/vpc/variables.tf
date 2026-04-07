# ============================================================
# VPC 모듈 입력 변수 정의
# 모듈 호출 시 전달받아야 하는 필수/선택 변수들
# ============================================================

# 리전 식별 이름 (리소스 태그 명명에 사용)
variable "region_name" {
  description = "리소스 명명에 사용할 리전 이름 (예: seoul, tokyo)"
  type        = string
}

# VPC CIDR 블록 (IP 주소 범위)
variable "cidr_block" {
  description = "VPC에서 사용할 CIDR 블록 (예: 10.2.0.0/16)"
  type        = string
}

# ------------------------------------------------------------
# 서브넷 관련 변수
# ------------------------------------------------------------

# 사용할 가용영역 개수
variable "az_count" {
  description = "사용할 가용영역(AZ) 개수 (고가용성을 위해 최소 2개 권장)"
  type        = number
}

# 퍼블릭 서브넷 개수
variable "public_subnet_count" {
  description = "생성할 퍼블릭 서브넷 개수 (인터넷 연결 필요한 리소스용)"
  type        = number
}

# 프라이빗 서브넷 개수
variable "private_subnet_count" {
  description = "생성할 프라이빗 서브넷 개수 (내부 리소스용, 외부 직접 접근 불가)"
  type        = number
}

# 서브넷 비트수
variable "subnet_bits" {
  description = "서브넷 CIDR 계산용 추가 비트수 (VPC /16 + 8 = 서브넷 /24)"
  type        = number
}
