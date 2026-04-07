# ============================================================
# EC2 모듈 입력 변수 정의
# EC2 인스턴스 생성에 필요한 모든 변수들
# ============================================================

# 리전 식별 이름 (리소스 태그 명명에 사용)
variable "region_name" {
  description = "리전 이름 (리소스 태그에 사용)"
  type        = string
}

# 퍼블릭 서브넷 ID 목록
variable "public_subnet_ids" {
  description = "퍼블릭 인스턴스를 배치할 서브넷 ID 목록"
  type        = list(string)
}

# 프라이빗 서브넷 ID 목록
variable "private_subnet_ids" {
  description = "프라이빗 인스턴스를 배치할 서브넷 ID 목록"
  type        = list(string)
}

# 보안 그룹 ID 맵 (이름 → ID)
variable "sg_ids" {
  description = "보안 그룹 이름을 키로 하는 ID 맵 (예: {web: sg-xxx})"
  type        = map(string)
}

# SSH 키 페어 이름
variable "key_name" {
  description = "EC2 인스턴스 접속용 SSH 키 페어 이름"
  type        = string
}

# ------------------------------------------------------------
# EC2 인스턴스 설정 맵
# 다양한 용도의 인스턴스를 하나의 변수로 정의
# ------------------------------------------------------------
variable "ec2-instances" {
  description = "EC2 인스턴스 설정 맵 (용도별 인스턴스 정의)"
  type = map(object({
    count         = number  # 생성할 인스턴스 개수
    ami           = string  # AMI ID (운영체제 이미지)
    instance_type = string  # 인스턴스 타입 (예: t3.micro)
    sg_name       = string  # 적용할 보안 그룹 이름
    public        = bool    # 퍼블릭 서브넷 배치 여부
    user_data     = string  # 부팅 시 실행할 스크립트
  }))
}
