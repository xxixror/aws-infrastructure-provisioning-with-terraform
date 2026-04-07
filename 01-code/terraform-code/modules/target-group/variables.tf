# ============================================================
# Target Group 모듈 입력 변수 정의
# 타겟 그룹 생성에 필요한 변수들
# ============================================================

# ------------------------------------------------------------
# 타겟 그룹 설정 객체
# 타겟 그룹의 모든 설정을 하나의 객체로 정의
# ------------------------------------------------------------
variable "target_group" {
  description = "타겟 그룹 상세 설정"
  type = object({
    target_type      = string  # 대상 유형 (instance/ip/lambda)
    name             = string  # 타겟 그룹 이름
    protocol         = string  # 트래픽 프로토콜 (HTTP/HTTPS/TCP)
    port             = number  # 트래픽 포트
    ip_address_type  = string  # IP 유형 (ipv4/ipv6)
    protocol_version = string  # HTTP 버전 (HTTP1/HTTP2/gRPC)
    
    # 헬스 체크 설정
    health_check = object({
      protocol            = string  # 헬스체크 프로토콜
      path                = string  # 헬스체크 경로
      port                = string  # 헬스체크 포트 ("traffic-port" 또는 포트번호)
      healthy_threshold   = number  # 정상 판정 연속 성공 횟수
      unhealthy_threshold = number  # 비정상 판정 연속 실패 횟수
      timeout             = number  # 응답 타임아웃(초)
      interval            = number  # 헬스체크 주기(초)
      matcher             = string  # 성공 HTTP 상태 코드
    })
  })
}

# 타겟 그룹이 속할 VPC ID
variable "vpc_id" {
  description = "타겟 그룹을 생성할 VPC의 ID"
  type        = string
}
