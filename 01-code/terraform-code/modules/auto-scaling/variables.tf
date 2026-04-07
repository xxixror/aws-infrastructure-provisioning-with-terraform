# ============================================================
# Auto Scaling 모듈 입력 변수 정의
# ASG 및 스케일링 정책 구성에 필요한 변수들
# ============================================================

# 인스턴스를 배포할 서브넷 ID 목록 (퍼블릭 또는 프라이빗)
variable "public_subnet_ids" {
  description = "Auto Scaling 인스턴스를 배포할 서브넷 ID 목록 (프라이빗 서브넷 사용 시 NAT Gateway 필요)"
  type        = list(string)
}

# 로드밸런서 타겟 그룹 ARN
variable "target_group_arn" {
  description = "인스턴스를 등록할 타겟 그룹의 ARN"
  type        = string
}

# 시작 템플릿 ID 맵 (템플릿 이름 → ID)
variable "lt_ids" {
  description = "시작 템플릿 이름을 키로 하는 템플릿 ID 맵"
  type        = map(string)
}

# ------------------------------------------------------------
# Auto Scaling Group 설정 객체
# ------------------------------------------------------------
variable "autoscaling_group" {
  description = "Auto Scaling 그룹의 상세 설정"
  type = object({
    name                      : string  # ASG 이름
    health_check_type         : string  # 헬스체크 유형 (EC2/ELB)
    health_check_grace_period : number  # 헬스체크 유예 기간(초)
    min_size                  : number  # 최소 인스턴스 수
    desired_capacity          : number  # 희망 인스턴스 수
    max_size                  : number  # 최대 인스턴스 수

    # 시작 템플릿 설정
    launch_template = object({
      instance_type = map(string)           # 인스턴스 타입별 가중치 맵
      template_name = string                # 기본 시작 템플릿 이름
      template_overrides = optional(map(string))  # 오버라이드용 템플릿 이름 맵 (인스턴스 타입 → 템플릿 이름)
    })
  })
}

# ------------------------------------------------------------
# Auto Scaling Policy 설정 객체
# ------------------------------------------------------------
variable "autoscaling_policy" {
  description = "Auto Scaling 정책 상세 설정"
  type = object({
    policy_type              = string  # 정책 유형 (TargetTrackingScaling 등)
    name                     = string  # 정책 이름
    estimated_instance_warmup = number  # 인스턴스 워밍업 시간(초)
    
    # 목표 추적 스케일링 설정
    config = object({
      metric_type  = string  # 추적할 지표 유형
      target_value = number  # 목표값 (이 값 유지하도록 스케일링)
    })
  })
}
