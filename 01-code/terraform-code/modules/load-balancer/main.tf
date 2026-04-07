# ============================================================
# Load Balancer 모듈 - Application Load Balancer 생성
# 트래픽을 여러 대상(EC2 인스턴스)으로 분산하는 로드밸런서입니다.
# ============================================================

# ------------------------------------------------------------
# Application Load Balancer (ALB) 생성
# Layer 7 로드밸런서로 HTTP/HTTPS 트래픽 처리
# ------------------------------------------------------------
resource "aws_lb" "this" {
  # 로드밸런서 유형: application(ALB), network(NLB), gateway(GLB)
  load_balancer_type = var.load_balancer.load_balancer_type
  
  # 로드밸런서 이름
  name = var.load_balancer.name
  
  # internal: true = 내부용(VPC 내부에서만 접근), false = 인터넷 경계(외부 접근 가능)
  internal = var.load_balancer.internal
  
  # IP 주소 유형: ipv4 또는 dualstack(IPv4 + IPv6)
  ip_address_type = var.load_balancer.ip_address_type
  
  # 로드밸런서를 배치할 서브넷 (최소 2개 가용영역 필요)
  subnets = var.public_subnet_ids
  
  # 로드밸런서에 적용할 보안 그룹
  # 인바운드: 외부에서 80/443 허용
  # 아웃바운드: 대상 인스턴스로 80 허용
  security_groups = [var.sg_ids[var.load_balancer.sg_name]]
}

# ------------------------------------------------------------
# 로드밸런서 리스너 (Listener) 생성
# 특정 포트/프로토콜로 들어오는 요청을 처리하는 규칙
# ------------------------------------------------------------
resource "aws_lb_listener" "this" {  # "main" → "this"로 통일
  # 이 리스너가 속할 로드밸런서 ARN
  load_balancer_arn = aws_lb.this.arn
  
  # 리스닝할 포트 (예: 80, 443)
  port = var.load_balancer_listener.port
  
  # 프로토콜 (HTTP, HTTPS, TCP 등)
  protocol = var.load_balancer_listener.protocol
  
  # ------------------------------------------------------------
  # 기본 액션 (Default Action)
  # 리스너로 들어온 요청을 어떻게 처리할지 정의
  # ------------------------------------------------------------
  default_action {
    # 액션 유형: forward(전달), redirect(리다이렉트), fixed-response(고정 응답) 등
    type = var.load_balancer_listener.type
    
    # 전달할 대상 그룹 ARN (type=forward일 때 필수)
    target_group_arn = var.target_group_arn
  }
}

# ALB와 WAF를 연결 (enable_waf가 true일 때만 생성)
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_acl_arn
}
