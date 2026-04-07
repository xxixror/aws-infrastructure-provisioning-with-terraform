# ============================================================
# Launch Template 모듈 입력 변수 정의
# 시작 템플릿 생성에 필요한 변수들
# ============================================================

# 리전 식별 이름 (리소스 태그에 사용)
variable "region_name" {
  description = "리전 이름 (태그 명명에 사용)"
  type        = string
}

# SSH 키 페어 이름
variable "key_name" {
  description = "EC2 인스턴스 접속용 SSH 키 페어 이름"
  type        = string
}

# 보안 그룹 ID 맵 (이름 → ID)
variable "sg_ids" {
  description = "보안 그룹 이름을 키로 하는 ID 맵"
  type        = map(string)
}

# 퍼블릭 서브넷 ID 목록
variable "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  type        = list(string)
}

# 프라이빗 서브넷 ID 목록
variable "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  type        = list(string)
}

# ------------------------------------------------------------
# AMI 이미지 맵
# 이름으로 AMI ID를 조회할 수 있는 맵
# ------------------------------------------------------------
variable "ami_images" {
  description = "AMI 이름을 키로 하는 AMI ID 맵 (예: {ec2-web: ami-xxx})"
  type        = map(string)
}

# ------------------------------------------------------------
# 시작 템플릿 설정 맵
# 여러 템플릿을 하나의 변수로 정의
# ------------------------------------------------------------
variable "templates" {
  description = "시작 템플릿 설정 맵 (템플릿별 상세 정보)"
  type = map(object({
    name        = string   # 템플릿 이름
    description = string   # 템플릿 설명
    ami_name    = string   # 사용할 AMI 이름 (ami_images 키 참조)
    public      = bool     # 퍼블릭 IP 할당 여부
    sg_name     = string   # 적용할 보안 그룹 이름
  }))
}
