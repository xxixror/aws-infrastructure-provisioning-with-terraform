# ============================================================
# Target Group 모듈 - 로드밸런서 대상 그룹 생성
# 로드밸런서가 트래픽을 분산할 대상(EC2 인스턴스 등)의 그룹
# ============================================================

# ------------------------------------------------------------
# 타겟 그룹 생성
# ALB/NLB에서 트래픽을 전달받을 대상 정의
# ------------------------------------------------------------
resource "aws_lb_target_group" "name" {
  # 대상 유형: instance(EC2), ip(IP 주소), lambda(Lambda 함수)
  target_type = var.target_group.target_type
  
  # 타겟 그룹 이름
  name = var.target_group.name
  
  # 트래픽 프로토콜 (HTTP, HTTPS, TCP 등)
  protocol = var.target_group.protocol
  
  # 트래픽 포트 (대상이 수신하는 포트)
  port = var.target_group.port
  
  # IP 주소 유형 (ipv4/ipv6)
  ip_address_type = var.target_group.ip_address_type
  
  # 타겟 그룹이 속할 VPC
  vpc_id = var.vpc_id
  
  # 프로토콜 버전 (HTTP1, HTTP2, gRPC)
  protocol_version = var.target_group.protocol_version
  
  # ------------------------------------------------------------
  # 헬스 체크 설정 (Health Check)
  # 대상 인스턴스의 상태를 주기적으로 확인
  # ------------------------------------------------------------
  health_check {
    # 헬스 체크 프로토콜
    protocol = var.target_group.health_check.protocol
    
    # 헬스 체크 경로 (HTTP/HTTPS인 경우 URL 경로)
    path = var.target_group.health_check.path
    
    # 헬스 체크 포트
    # "traffic-port": 트래픽 포트와 동일한 포트 사용
    port = var.target_group.health_check.port
    
    # 정상 판정 임계값: 연속 성공 횟수
    # 이 횟수만큼 연속 성공해야 '정상' 상태로 변경
    healthy_threshold = var.target_group.health_check.healthy_threshold
    
    # 비정상 판정 임계값: 연속 실패 횟수
    # 이 횟수만큼 연속 실패해야 '비정상' 상태로 변경
    unhealthy_threshold = var.target_group.health_check.unhealthy_threshold
    
    # 타임아웃(초): 응답 대기 시간
    # 이 시간 내에 응답이 없으면 실패로 간주
    timeout = var.target_group.health_check.timeout
    
    # 인터벌(초): 헬스 체크 주기
    # 각 헬스 체크 사이의 간격
    interval = var.target_group.health_check.interval
    
    # 성공 응답 코드: HTTP 상태 코드
    # 예: "200", "200-299", "200,201"
    matcher = var.target_group.health_check.matcher
  }
}
