# ============================================================
# Auto Scaling 모듈
# 프로젝트 목적: 트래픽 변화에 따라 EC2 인스턴스 수를 자동으로 조절
# 학습 목표: AWS Auto Scaling Group과 스케일링 정책 이해
# ============================================================

# ------------------------------------------------------------
# Auto Scaling Group (ASG) 리소스
# 역할: EC2 인스턴스 그룹을 관리하고 자동으로 확장/축소 수행
# ------------------------------------------------------------
resource "aws_autoscaling_group" "main" {
  # ASG 이름: AWS 콘솔에서 식별하는 이름
  name = var.autoscaling_group.name
  
  # 서브넷 설정: 인스턴스를 배포할 서브넷 목록
  # 퍼블릭 서브넷 사용 → 인터넷에서 직접 접근 가능
  vpc_zone_identifier = var.public_subnet_ids
  
  # 타겟 그룹 연결: 로드밸런서의 타겟 그룹과 연동
  # ASG로 생성된 인스턴스가 자동으로 타겟 그룹에 등록됨
  target_group_arns = [var.target_group_arn]
  
  # 헬스 체크 유형: ELB(로드밸런서) 또는 EC2
  # ELB 선택 시: 로드밸런서의 헬스체크 결과로 인스턴스 상태 판단
  # 비정상 인스턴스는 자동으로 교체됨
  health_check_type = var.autoscaling_group.health_check_type
  
  # 헬스 체크 유예 기간(초): 새 인스턴스 시작 후 헬스체크 시작까지 대기 시간
  # WordPress 같은 애플리케이션은 시작 시간이 필요하므로 충분한 시간 설정
  health_check_grace_period = var.autoscaling_group.health_check_grace_period

  # 인스턴스 개수 제한 설정
  min_size         = var.autoscaling_group.min_size          # 최소 인스턴스 수 (항상 유지)
  desired_capacity = var.autoscaling_group.desired_capacity # 희망 인스턴스 수 (초기 목표)
  max_size         = var.autoscaling_group.max_size          # 최대 인스턴스 수 (상한선)

  # 태그 설정: Auto Scaling으로 생성되는 모든 인스턴스에 자동 적용
  # propagate_at_launch = true: 새로 생성되는 인스턴스에도 태그 전파
  tag {
    key                 = "Name"
    value               = "wordpress-js"
    propagate_at_launch = true
  }

  # ------------------------------------------------------------
  # 혼합 인스턴스 정책 (Mixed Instances Policy)
  # 목적: 여러 인스턴스 타입을 혼합하여 비용 최적화 및 가용성 확보
  # 학습 포인트: Spot Instance와 On-Demand Instance 혼합 사용 가능
  # ------------------------------------------------------------
  mixed_instances_policy {
    launch_template {
      # 사용할 Launch Template 지정
      launch_template_specification {
        # 템플릿 ID: 템플릿 이름으로 ID 조회
        launch_template_id = var.lt_ids[var.autoscaling_group.launch_template.template_name]
        # 버전: $Latest = 항상 최신 버전 사용
        version = "$Latest"
      }
      
      # 인스턴스 타입 오버라이드: 여러 인스턴스 타입 지정 가능
      # 예: t3.micro, t3.small 등을 혼합 사용하여 비용 절감
      dynamic "override" {
        for_each = var.autoscaling_group.launch_template.instance_type
        content {
          # 인스턴스 타입 (예: t3.micro)
          instance_type = override.key
          # 가중치: 해당 타입 1대가 차지하는 용량 단위
          # 예: "1" = 1대당 1단위, "2" = 1대당 2단위 (더 큰 인스턴스)
          weighted_capacity = override.value
          
          # 템플릿 오버라이드: 특정 인스턴스 타입에 다른 Launch Template 사용
          # (현재 프로젝트에서는 사용하지 않음)
          dynamic "launch_template_specification" {
            for_each = try(var.autoscaling_group.launch_template.template_overrides[override.key] != null, false) ? [1] : []
            content {
              launch_template_id = var.lt_ids[var.autoscaling_group.launch_template.template_overrides[override.key]]
              version = "$Latest"
            }
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------
# Auto Scaling Policy 리소스
# 역할: 스케일링 조건과 방식을 정의하는 정책 생성
# 학습 목표: Target Tracking Scaling 정책 이해
# ------------------------------------------------------------
resource "aws_autoscaling_policy" "name" {
  # 이 정책이 적용될 Auto Scaling 그룹
  autoscaling_group_name = aws_autoscaling_group.main.name
  
  # 정책 유형: TargetTrackingScaling(목표 추적), StepScaling(단계별) 등
  # TargetTrackingScaling: 지정한 지표를 목표값으로 유지하도록 자동 조절
  policy_type = var.autoscaling_policy.policy_type
  
  # 정책 이름: AWS 콘솔에서 식별하는 이름
  name = var.autoscaling_policy.name
  
  # 인스턴스 워밍업 시간(초): 새 인스턴스가 CloudWatch 지표에 반영되기까지 대기 시간
  # 새 인스턴스는 시작 직후 지표가 불안정하므로 이 시간 동안은 스케일링 판단에서 제외
  estimated_instance_warmup = var.autoscaling_policy.estimated_instance_warmup
  
  # ------------------------------------------------------------
  # 목표 추적 스케일링 설정 (Target Tracking Configuration)
  # 동작 원리: 지정한 지표가 목표값을 유지하도록 인스턴스 수를 자동 조절
  # 
  # 예시:
  # - 목표값: CPU 60%
  # - 현재 CPU 80% → 인스턴스 추가 (스케일 아웃)
  # - 현재 CPU 40% → 인스턴스 제거 (스케일 인)
  # ------------------------------------------------------------
  target_tracking_configuration {
    # 사전 정의된 지표 사용 (AWS에서 제공하는 기본 지표)
    predefined_metric_specification {
      # 지표 유형:
      # - ASGAverageCPUUtilization: Auto Scaling Group의 평균 CPU 사용률
      # - ALBRequestCountPerTarget: 타겟당 요청 수
      # - 기타 AWS 제공 지표들
      predefined_metric_type = var.autoscaling_policy.config.metric_type
    }
    # 목표값: 이 값을 유지하도록 인스턴스 수 자동 조절
    # 예: target_value = 60 → CPU 사용률 60%를 목표로 유지
    #     CPU가 60%를 초과하면 인스턴스 추가, 미만이면 인스턴스 제거
    target_value = var.autoscaling_policy.config.target_value
  }
}
