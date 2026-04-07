# ============================================================
# Load Balancer 모듈 입력 변수 정의
# ALB 생성에 필요한 변수들
# ============================================================

# 로드밸런서를 배치할 퍼블릭 서브넷 ID 목록
variable "public_subnet_ids" {
  description = "로드밸런서를 배치할 서브넷 ID 목록 (최소 2개 가용영역)"
  type        = list(string)
}

# 보안 그룹 ID 맵 (이름 → ID)
variable "sg_ids" {
  description = "보안 그룹 이름을 키로 하는 ID 맵"
  type        = map(string)
}

# 트래픽을 전달할 타겟 그룹 ARN
variable "target_group_arn" {
  description = "트래픽을 전달할 대상 그룹의 ARN"
  type        = string
}

# ------------------------------------------------------------
# 로드밸런서 설정 객체
# ------------------------------------------------------------
variable "load_balancer" {
  description = "로드밸런서 상세 설정"
  type = object({
    load_balancer_type = string  # 로드밸런서 유형 (application/network/gateway)
    name               = string  # 로드밸런서 이름
    internal           = bool    # 내부용 여부 (true: 내부, false: 인터넷 facing)
    ip_address_type    = string  # IP 유형 (ipv4/dualstack)
    sg_name            = string  # 적용할 보안 그룹 이름
  })
}

# ------------------------------------------------------------
# 로드밸런서 리스너 설정 객체
# ------------------------------------------------------------
variable "load_balancer_listener" {
  description = "로드밸런서 리스너 설정"
  type = object({
    protocol = string  # 리스닝 프로토콜 (HTTP/HTTPS)
    port     = number  # 리스닝 포트 (80/443)
    type     = string  # 액션 유형 (forward/redirect/fixed-response)
  })
}

variable "enable_waf" {
  description = "WAF 연결 활성화 여부"
  type        = bool
  default     = false
}

variable "waf_acl_arn" {
  description = "WAF 모듈로부터 전달받은 ACL ARN"
  type        = string
  default     = ""
}
